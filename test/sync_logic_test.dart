import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ordersync/data/datasources/local_storage_service.dart';
import 'package:ordersync/data/datasources/mock_remote_datasource.dart';
import 'package:ordersync/data/models/order.dart';
import 'package:ordersync/data/models/order_status.dart';
import 'package:ordersync/data/repositories/order_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService localStorage;
  late MockRemoteDataSource remoteDataSource;
  late OrderRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    localStorage = LocalStorageService();
    await localStorage.init();
    remoteDataSource = MockRemoteDataSource();
    repository = OrderRepository(
      localStorage: localStorage,
      remoteDataSource: remoteDataSource,
    );
  });

  group('Offline Sync & Queue Integration Tests', () {
    test('Updating status while offline should save order to local DB with pendingSync state', () async {
      await repository.loadOrders(isOnline: true);

      final updated = await repository.updateOrderStatus(
        orderId: 'ORD-8492',
        newStatus: OrderStatus.accepted,
        isOnline: false,
      );

      expect(updated.status, equals(OrderStatus.accepted));
      expect(updated.syncState, equals(SyncState.pendingSync));

      final queue = repository.getPendingQueue();
      expect(queue.length, equals(1));
      expect(queue.first.orderId, equals('ORD-8492'));
      expect(queue.first.targetStatus, equals(OrderStatus.accepted));
    });

    test('Sequential Queue processing should drain queue and update server state when online', () async {
      await repository.loadOrders(isOnline: true);

      // Enqueue 2 offline updates
      await repository.updateOrderStatus(
        orderId: 'ORD-8492',
        newStatus: OrderStatus.accepted,
        isOnline: false,
      );
      await repository.updateOrderStatus(
        orderId: 'ORD-7104',
        newStatus: OrderStatus.packed,
        isOnline: false,
      );

      expect(repository.getPendingQueue().length, equals(2));

      // Process queue
      final result = await repository.processPendingQueue();

      expect(result.syncedCount + result.conflictCount, equals(2));
      expect(repository.getPendingQueue().length, equals(0));

      final serverOrd1 = await remoteDataSource.getOrder('ORD-8492');
      expect(serverOrd1?.order.status, equals(OrderStatus.accepted));
    });

    test('Conflicting offline update should trigger conflict log and apply resolution rule', () async {
      await repository.loadOrders(isOnline: true);

      // Offline update ORD-8492 to Cancelled
      await repository.updateOrderStatus(
        orderId: 'ORD-8492',
        newStatus: OrderStatus.cancelled,
        isOnline: false,
      );

      // Artificially change server to Delivered before sync
      remoteDataSource.simulateServerSideChange('ORD-8492', OrderStatus.delivered);

      // Sync queue
      final result = await repository.processPendingQueue();

      expect(result.conflictCount, equals(1));
      expect(result.conflicts.length, equals(1));
      expect(result.conflicts.first.resolvedStatus, equals(OrderStatus.delivered));

      final conflictLogs = repository.getConflictLogs();
      expect(conflictLogs.isNotEmpty, isTrue);
      expect(conflictLogs.first.orderId, equals('ORD-8492'));
    });
  });
}
