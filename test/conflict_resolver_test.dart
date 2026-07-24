import 'package:flutter_test/flutter_test.dart';
import 'package:ordersync/core/utils/conflict_resolver.dart';
import 'package:ordersync/data/models/order_status.dart';

void main() {
  group('ConflictResolver Logic Tests', () {
    final now = DateTime.now();

    test('Identical server and client status should return no conflict', () {
      final result = ConflictResolver.resolve(
        serverStatus: OrderStatus.accepted,
        clientStatus: OrderStatus.accepted,
        serverTimestamp: now,
        clientTimestamp: now,
      );

      expect(result.isConflict, isFalse);
      expect(result.winningStatus, equals(OrderStatus.accepted));
      expect(result.strategy, equals('Direct Match'));
    });

    test('Server Delivered vs Client Cancelled should resolve to Server Delivered (Terminal Precedence)', () {
      final result = ConflictResolver.resolve(
        serverStatus: OrderStatus.delivered,
        clientStatus: OrderStatus.cancelled,
        serverTimestamp: now.subtract(const Duration(minutes: 10)),
        clientTimestamp: now,
      );

      expect(result.isConflict, isTrue);
      expect(result.winningStatus, equals(OrderStatus.delivered));
      expect(result.strategy, contains('Terminal Precedence'));
    });

    test('Server Cancelled vs Client Delivered should resolve to Server Cancelled', () {
      final result = ConflictResolver.resolve(
        serverStatus: OrderStatus.cancelled,
        clientStatus: OrderStatus.delivered,
        serverTimestamp: now.subtract(const Duration(minutes: 5)),
        clientTimestamp: now,
      );

      expect(result.isConflict, isTrue);
      expect(result.winningStatus, equals(OrderStatus.cancelled));
    });

    test('Client higher rank (Pending -> Packed) advances status over lower server rank (Pending)', () {
      final result = ConflictResolver.resolve(
        serverStatus: OrderStatus.pending,
        clientStatus: OrderStatus.packed,
        serverTimestamp: now.subtract(const Duration(hours: 1)),
        clientTimestamp: now,
      );

      expect(result.isConflict, isTrue);
      expect(result.winningStatus, equals(OrderStatus.packed));
      expect(result.strategy, equals('Progressive Rank Advancement'));
    });

    test('Server higher rank (Shipped) ignores regressive offline update (Accepted)', () {
      final result = ConflictResolver.resolve(
        serverStatus: OrderStatus.shipped,
        clientStatus: OrderStatus.accepted,
        serverTimestamp: now.subtract(const Duration(minutes: 30)),
        clientTimestamp: now,
      );

      expect(result.isConflict, isTrue);
      expect(result.winningStatus, equals(OrderStatus.shipped));
      expect(result.strategy, contains('Regressive Update Ignored'));
    });
  });
}
