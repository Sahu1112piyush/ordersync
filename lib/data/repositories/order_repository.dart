import 'package:uuid/uuid.dart';
import '../../core/utils/conflict_resolver.dart';
import '../datasources/local_storage_service.dart';
import '../datasources/mock_remote_datasource.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../models/sync_action.dart';
import '../models/sync_conflict.dart';

class SyncProcessResult {
  final int syncedCount;
  final int conflictCount;
  final List<SyncConflictLog> conflicts;

  SyncProcessResult({
    required this.syncedCount,
    required this.conflictCount,
    required this.conflicts,
  });
}

class OrderRepository {
  final LocalStorageService localStorage;
  final MockRemoteDataSource remoteDataSource;
  final _uuid = const Uuid();

  OrderRepository({
    required this.localStorage,
    required this.remoteDataSource,
  });

  /// Initialize local orders cache if empty
  Future<List<OrderModel>> loadOrders({required bool isOnline}) async {
    List<OrderModel> cached = localStorage.getOrders();

    if (isOnline) {
      try {
        final remoteOrders = await remoteDataSource.fetchOrders();
        // Merge remote orders with local pending sync states if any local order is pending_sync
        final queue = localStorage.getSyncQueue();
        final pendingOrderIds = queue.map((a) => a.orderId).toSet();

        final merged = remoteOrders.map((remote) {
          if (pendingOrderIds.contains(remote.id)) {
            final local = cached.firstWhere((c) => c.id == remote.id, orElse: () => remote);
            return local;
          }
          return remote;
        }).toList();

        await localStorage.saveOrders(merged);
        return merged;
      } catch (_) {
        return cached;
      }
    }

    if (cached.isEmpty) {
      // Seed local storage from remote datasource initial state if offline on first start
      final initialRemote = await remoteDataSource.fetchOrders();
      await localStorage.saveOrders(initialRemote);
      return initialRemote;
    }

    return cached;
  }

  /// Update an order status (Online: immediate remote API update; Offline: enqueue into Local Database)
  Future<OrderModel> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    required bool isOnline,
    String? note,
  }) async {
    final currentOrders = localStorage.getOrders();
    final existingIndex = currentOrders.indexWhere((o) => o.id == orderId);

    if (existingIndex == -1) {
      throw Exception('Order $orderId not found locally');
    }

    final currentOrder = currentOrders[existingIndex];
    final now = DateTime.now();

    if (!isOnline) {
      // --- OFFLINE MODE ---
      final updatedOrder = currentOrder.copyWith(
        status: newStatus,
        updatedAt: now,
        syncState: SyncState.pendingSync,
      );

      // 1. Update local cache
      currentOrders[existingIndex] = updatedOrder;
      await localStorage.saveOrders(currentOrders);

      // 2. Add to sequential queue
      final queue = localStorage.getSyncQueue();
      queue.add(SyncAction(
        actionId: _uuid.v4(),
        orderId: orderId,
        previousStatus: currentOrder.status,
        targetStatus: newStatus,
        timestamp: now,
        note: note,
      ));
      await localStorage.saveSyncQueue(queue);

      return updatedOrder;
    } else {
      // --- ONLINE MODE ---
      try {
        // First check server state to verify no conflict exists
        final serverInfo = await remoteDataSource.getOrder(orderId);

        if (serverInfo != null && serverInfo.order.status != currentOrder.status) {
          final resolution = ConflictResolver.resolve(
            serverStatus: serverInfo.order.status,
            clientStatus: newStatus,
            serverTimestamp: serverInfo.serverTimestamp,
            clientTimestamp: now,
          );

          if (resolution.isConflict) {
            // Record conflict
            final conflictLog = SyncConflictLog(
              id: _uuid.v4(),
              orderId: orderId,
              customerName: currentOrder.customerName,
              serverStatus: serverInfo.order.status,
              clientStatus: newStatus,
              resolvedStatus: resolution.winningStatus,
              resolutionStrategy: resolution.strategy,
              timestamp: now,
            );
            await _addConflictLog(conflictLog);

            final remoteRes = await remoteDataSource.updateOrderStatus(orderId, resolution.winningStatus);
            final updatedOrder = remoteRes.order.copyWith(
              syncState: SyncState.conflict,
              lastConflictReason: resolution.explanation,
            );
            currentOrders[existingIndex] = updatedOrder;
            await localStorage.saveOrders(currentOrders);
            return updatedOrder;
          }
        }

        // Direct server update
        final remoteRes = await remoteDataSource.updateOrderStatus(orderId, newStatus);
        final updatedOrder = remoteRes.order;
        currentOrders[existingIndex] = updatedOrder;
        await localStorage.saveOrders(currentOrders);
        return updatedOrder;
      } catch (e) {
        // Fallback to queue if server network call fails unexpectedly
        return updateOrderStatus(
          orderId: orderId,
          newStatus: newStatus,
          isOnline: false,
          note: note,
        );
      }
    }
  }

  /// PROCESS QUEUE SEQUENTIALLY (FIFO) WHEN INTERNET COMES BACK ONLINE
  Future<SyncProcessResult> processPendingQueue() async {
    final queue = localStorage.getSyncQueue();
    if (queue.isEmpty) {
      return SyncProcessResult(syncedCount: 0, conflictCount: 0, conflicts: []);
    }

    final currentOrders = localStorage.getOrders();
    final List<SyncConflictLog> newConflicts = [];
    int syncedCount = 0;
    int conflictCount = 0;

    final List<SyncAction> remainingQueue = List.from(queue);

    // Sequential Queue Iteration (One-by-one FIFO)
    for (var action in queue) {
      try {
        final serverInfo = await remoteDataSource.getOrder(action.orderId);

        if (serverInfo == null) {
          remainingQueue.remove(action);
          continue;
        }

        final resolution = ConflictResolver.resolve(
          serverStatus: serverInfo.order.status,
          clientStatus: action.targetStatus,
          serverTimestamp: serverInfo.serverTimestamp,
          clientTimestamp: action.timestamp,
        );

        final orderIndex = currentOrders.indexWhere((o) => o.id == action.orderId);

        if (resolution.isConflict) {
          conflictCount++;
          final conflictLog = SyncConflictLog(
            id: _uuid.v4(),
            orderId: action.orderId,
            customerName: orderIndex != -1 ? currentOrders[orderIndex].customerName : 'Unknown',
            serverStatus: serverInfo.order.status,
            clientStatus: action.targetStatus,
            resolvedStatus: resolution.winningStatus,
            resolutionStrategy: resolution.strategy,
            timestamp: DateTime.now(),
          );
          newConflicts.add(conflictLog);
          await _addConflictLog(conflictLog);

          // Update server with winning status
          final remoteRes = await remoteDataSource.updateOrderStatus(action.orderId, resolution.winningStatus);

          if (orderIndex != -1) {
            currentOrders[orderIndex] = remoteRes.order.copyWith(
              syncState: SyncState.conflict,
              lastConflictReason: resolution.explanation,
            );
          }
        } else {
          // Normal sync - apply client status to server
          syncedCount++;
          final remoteRes = await remoteDataSource.updateOrderStatus(action.orderId, action.targetStatus);

          if (orderIndex != -1) {
            currentOrders[orderIndex] = remoteRes.order.copyWith(
              syncState: SyncState.synced,
              lastConflictReason: null,
            );
          }
        }

        remainingQueue.remove(action);
      } catch (e) {
        // If an error occurs on a specific item, increment retry count and retain for next sync attempt
        final index = remainingQueue.indexOf(action);
        if (index != -1) {
          remainingQueue[index] = action.copyWith(retryCount: action.retryCount + 1);
        }
        break; // Stop sequential loop if connectivity broke mid-sync
      }
    }

    await localStorage.saveSyncQueue(remainingQueue);
    await localStorage.saveOrders(currentOrders);

    return SyncProcessResult(
      syncedCount: syncedCount,
      conflictCount: conflictCount,
      conflicts: newConflicts,
    );
  }

  Future<void> _addConflictLog(SyncConflictLog log) async {
    final logs = localStorage.getConflictLogs();
    logs.insert(0, log);
    await localStorage.saveConflictLogs(logs);
  }

  List<SyncAction> getPendingQueue() => localStorage.getSyncQueue();
  List<SyncConflictLog> getConflictLogs() => localStorage.getConflictLogs();

  /// Utility to clear queue manually from settings for debug/testing
  Future<void> clearQueue() async {
    await localStorage.saveSyncQueue([]);
  }
}
