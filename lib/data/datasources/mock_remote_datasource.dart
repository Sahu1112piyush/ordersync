import '../models/order.dart';
import '../models/order_item.dart';
import '../models/order_status.dart';

class RemoteOrderResponse {
  final OrderModel order;
  final DateTime serverTimestamp;

  RemoteOrderResponse({required this.order, required this.serverTimestamp});
}

class MockRemoteDataSource {
  final Map<String, OrderModel> _serverDatabase = {};

  MockRemoteDataSource() {
    _seedInitialOrders();
  }

  void _seedInitialOrders() {
    final seedOrders = [
      OrderModel(
        id: 'ORD-8492',
        customerName: 'Rahul Sharma',
        phone: '+91 98765 43210',
        address: '42 Connaught Place, Block B, New Delhi',
        items: const [
          OrderItem(id: 'P-101', name: 'Wireless Ergonomic Keyboard', quantity: 1, unitPrice: 3499.0),
          OrderItem(id: 'P-102', name: 'USB-C Fast Charging Cable', quantity: 2, unitPrice: 499.0),
        ],
        totalAmount: 4497.0,
        paymentStatus: 'Paid',
        status: OrderStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      OrderModel(
        id: 'ORD-7104',
        customerName: 'Priya Verma',
        phone: '+91 91234 56789',
        address: '108 Park Street, 3rd Floor, Kolkata',
        items: const [
          OrderItem(id: 'P-201', name: 'Noise-Cancelling Headphones', quantity: 1, unitPrice: 8999.0),
        ],
        totalAmount: 8999.0,
        paymentStatus: 'Paid',
        status: OrderStatus.accepted,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      OrderModel(
        id: 'ORD-6239',
        customerName: 'Amit Patel',
        phone: '+91 99887 76655',
        address: '15 SG Highway, Satellite, Ahmedabad',
        items: const [
          OrderItem(id: 'P-301', name: 'Smartwatch Series 5', quantity: 1, unitPrice: 12499.0),
          OrderItem(id: 'P-302', name: 'Screen Protector Guard', quantity: 2, unitPrice: 299.0),
        ],
        totalAmount: 13097.0,
        paymentStatus: 'Cash on Delivery',
        status: OrderStatus.packed,
        createdAt: DateTime.now().subtract(const Duration(hours: 10)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      OrderModel(
        id: 'ORD-5190',
        customerName: 'Sneha Kapoor',
        phone: '+91 97112 23344',
        address: '88 Cyber City, Phase 2, Gurgaon',
        items: const [
          OrderItem(id: 'P-401', name: 'UltraHD LED Monitor 27"', quantity: 1, unitPrice: 18500.0),
        ],
        totalAmount: 18500.0,
        paymentStatus: 'Paid',
        status: OrderStatus.shipped,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      OrderModel(
        id: 'ORD-4021',
        customerName: 'Vikram Singh',
        phone: '+91 94567 89012',
        address: '23 Bannerghatta Main Road, Bengaluru',
        items: const [
          OrderItem(id: 'P-501', name: 'Portable Bluetooth Speaker', quantity: 2, unitPrice: 2499.0),
        ],
        totalAmount: 4998.0,
        paymentStatus: 'Paid',
        status: OrderStatus.delivered,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    for (var order in seedOrders) {
      _serverDatabase[order.id] = order;
    }
  }

  Future<List<OrderModel>> fetchOrders() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _serverDatabase.values.toList();
  }

  Future<RemoteOrderResponse?> getOrder(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final order = _serverDatabase[orderId];
    if (order == null) return null;
    return RemoteOrderResponse(
      order: order,
      serverTimestamp: order.updatedAt,
    );
  }

  Future<RemoteOrderResponse> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final existing = _serverDatabase[orderId];
    final now = DateTime.now();

    if (existing == null) {
      throw Exception('Order $orderId not found on server');
    }

    final updated = existing.copyWith(
      status: newStatus,
      updatedAt: now,
      syncState: SyncState.synced,
    );

    _serverDatabase[orderId] = updated;
    return RemoteOrderResponse(order: updated, serverTimestamp: now);
  }

  /// Helper to force server status to simulate offline conflict testing
  void simulateServerSideChange(String orderId, OrderStatus status) {
    if (_serverDatabase.containsKey(orderId)) {
      _serverDatabase[orderId] = _serverDatabase[orderId]!.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
    }
  }
}
