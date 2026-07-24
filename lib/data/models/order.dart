import 'order_item.dart';
import 'order_status.dart';

enum SyncState { synced, pendingSync, conflict }

class OrderModel {
  final String id;
  final String customerName;
  final String phone;
  final String address;
  final List<OrderItem> items;
  final double totalAmount;
  final String paymentStatus; // e.g. 'Paid', 'Pending', 'COD'
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncState syncState;
  final String? lastConflictReason;

  const OrderModel({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.items,
    required this.totalAmount,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.syncState = SyncState.synced,
    this.lastConflictReason,
  });

  OrderModel copyWith({
    String? id,
    String? customerName,
    String? phone,
    String? address,
    List<OrderItem>? items,
    double? totalAmount,
    String? paymentStatus,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncState? syncState,
    String? lastConflictReason,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      lastConflictReason: lastConflictReason ?? this.lastConflictReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'phone': phone,
      'address': address,
      'items': items.map((x) => x.toJson()).toList(),
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncState': syncState.name,
      'lastConflictReason': lastConflictReason,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      customerName: json['customerName'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      items: (json['items'] as List)
          .map((x) => OrderItem.fromJson(x as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paymentStatus: json['paymentStatus'] as String,
      status: OrderStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      syncState: SyncState.values.firstWhere(
        (e) => e.name == json['syncState'],
        orElse: () => SyncState.synced,
      ),
      lastConflictReason: json['lastConflictReason'] as String?,
    );
  }
}
