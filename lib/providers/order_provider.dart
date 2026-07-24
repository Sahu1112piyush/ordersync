import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/mock_remote_datasource.dart';
import '../data/models/order.dart';
import '../data/models/order_status.dart';
import '../data/models/sync_action.dart';
import '../data/models/sync_conflict.dart';
import '../data/repositories/order_repository.dart';
import 'connectivity_provider.dart';

class OrderState {
  final List<OrderModel> orders;
  final bool isLoading;
  final bool isSyncing;
  final String searchQuery;
  final OrderStatus? statusFilter;
  final List<SyncAction> pendingQueue;
  final List<SyncConflictLog> conflictLogs;
  final String? errorMessage;
  final String? lastSyncNotification;

  const OrderState({
    required this.orders,
    this.isLoading = false,
    this.isSyncing = false,
    this.searchQuery = '',
    this.statusFilter,
    this.pendingQueue = const [],
    this.conflictLogs = const [],
    this.errorMessage,
    this.lastSyncNotification,
  });

  List<OrderModel> get filteredOrders {
    return orders.where((order) {
      final matchesSearch = searchQuery.isEmpty ||
          order.id.toLowerCase().contains(searchQuery.toLowerCase()) ||
          order.customerName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          order.items.any((item) => item.name.toLowerCase().contains(searchQuery.toLowerCase()));

      final matchesStatus = statusFilter == null || order.status == statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  OrderState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    bool? isSyncing,
    String? searchQuery,
    OrderStatus? Function()? statusFilter,
    List<SyncAction>? pendingQueue,
    List<SyncConflictLog>? conflictLogs,
    String? Function()? errorMessage,
    String? Function()? lastSyncNotification,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      pendingQueue: pendingQueue ?? this.pendingQueue,
      conflictLogs: conflictLogs ?? this.conflictLogs,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      lastSyncNotification:
          lastSyncNotification != null ? lastSyncNotification() : this.lastSyncNotification,
    );
  }
}

final mockRemoteDataSourceProvider = Provider<MockRemoteDataSource>((ref) {
  return MockRemoteDataSource();
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  final remoteDataSource = ref.watch(mockRemoteDataSourceProvider);
  return OrderRepository(
    localStorage: localStorage,
    remoteDataSource: remoteDataSource,
  );
});

class OrderNotifier extends Notifier<OrderState> {
  @override
  OrderState build() {
    ref.listen<NetworkState>(connectivityProvider, (previous, next) {
      if (previous?.isEffectiveOnline == false && next.isEffectiveOnline == true) {
        syncPendingQueue();
      }
    });

    // Initial load
    Future.microtask(() => loadOrders());

    return const OrderState(orders: [], isLoading: true);
  }

  OrderRepository get repository => ref.read(orderRepositoryProvider);

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    final isOnline = ref.read(connectivityProvider).isEffectiveOnline;

    try {
      final orders = await repository.loadOrders(isOnline: isOnline);
      final queue = repository.getPendingQueue();
      final conflicts = repository.getConflictLogs();

      state = state.copyWith(
        orders: orders,
        isLoading: false,
        pendingQueue: queue,
        conflictLogs: conflicts,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'Failed to load orders: ${e.toString()}',
      );
    }
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? note,
  }) async {
    final isOnline = ref.read(connectivityProvider).isEffectiveOnline;

    try {
      final updatedOrder = await repository.updateOrderStatus(
        orderId: orderId,
        newStatus: newStatus,
        isOnline: isOnline,
        note: note,
      );

      final updatedOrders = state.orders.map((o) => o.id == orderId ? updatedOrder : o).toList();
      final queue = repository.getPendingQueue();
      final conflicts = repository.getConflictLogs();

      String? notificationMsg;
      if (!isOnline) {
        notificationMsg =
            'Saved to offline queue! Order ${updatedOrder.id} status set to ${newStatus.displayName}.';
      } else if (updatedOrder.syncState == SyncState.conflict) {
        notificationMsg =
            'Sync Conflict Resolved: ${updatedOrder.lastConflictReason ?? "Server state updated"}';
      } else {
        notificationMsg = 'Order ${updatedOrder.id} updated live to ${newStatus.displayName}.';
      }

      state = state.copyWith(
        orders: updatedOrders,
        pendingQueue: queue,
        conflictLogs: conflicts,
        lastSyncNotification: () => notificationMsg,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: () => 'Update failed: ${e.toString()}');
    }
  }

  Future<void> syncPendingQueue() async {
    if (state.pendingQueue.isEmpty) return;

    final isOnline = ref.read(connectivityProvider).isEffectiveOnline;
    if (!isOnline) {
      state = state.copyWith(
        lastSyncNotification: () => 'Device is offline. Connect to network to sync updates.',
      );
      return;
    }

    state = state.copyWith(isSyncing: true);

    try {
      final result = await repository.processPendingQueue();
      final orders = await repository.loadOrders(isOnline: true);
      final queue = repository.getPendingQueue();
      final conflicts = repository.getConflictLogs();

      String message;
      if (result.conflictCount > 0) {
        message =
            'Sync completed! ${result.syncedCount} synced, ${result.conflictCount} conflicts resolved.';
      } else {
        message = 'Successfully synced ${result.syncedCount} pending updates to server!';
      }

      state = state.copyWith(
        orders: orders,
        isSyncing: false,
        pendingQueue: queue,
        conflictLogs: conflicts,
        lastSyncNotification: () => message,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: () => 'Sync process failed: ${e.toString()}',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(OrderStatus? filter) {
    state = state.copyWith(statusFilter: () => filter);
  }

  void simulateServerSideStatus(String orderId, OrderStatus status) {
    ref.read(mockRemoteDataSourceProvider).simulateServerSideChange(orderId, status);
    state = state.copyWith(
      lastSyncNotification: () =>
          'Server state for $orderId artificially changed to ${status.displayName}. Try syncing offline updates now!',
    );
  }

  Future<void> clearQueueManually() async {
    await repository.clearQueue();
    state = state.copyWith(
      pendingQueue: [],
      lastSyncNotification: () => 'Offline sync queue cleared.',
    );
  }

  void clearNotification() {
    state = state.copyWith(lastSyncNotification: () => null, errorMessage: () => null);
  }
}

final orderProvider = NotifierProvider<OrderNotifier, OrderState>(
  OrderNotifier.new,
);
