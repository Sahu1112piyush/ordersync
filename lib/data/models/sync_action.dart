import 'order_status.dart';

class SyncAction {
  final String actionId;
  final String orderId;
  final OrderStatus previousStatus;
  final OrderStatus targetStatus;
  final DateTime timestamp;
  final int retryCount;
  final String? note;

  const SyncAction({
    required this.actionId,
    required this.orderId,
    required this.previousStatus,
    required this.targetStatus,
    required this.timestamp,
    this.retryCount = 0,
    this.note,
  });

  SyncAction copyWith({
    String? actionId,
    String? orderId,
    OrderStatus? previousStatus,
    OrderStatus? targetStatus,
    DateTime? timestamp,
    int? retryCount,
    String? note,
  }) {
    return SyncAction(
      actionId: actionId ?? this.actionId,
      orderId: orderId ?? this.orderId,
      previousStatus: previousStatus ?? this.previousStatus,
      targetStatus: targetStatus ?? this.targetStatus,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'actionId': actionId,
      'orderId': orderId,
      'previousStatus': previousStatus.name,
      'targetStatus': targetStatus.name,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
      'note': note,
    };
  }

  factory SyncAction.fromJson(Map<String, dynamic> json) {
    return SyncAction(
      actionId: json['actionId'] as String,
      orderId: json['orderId'] as String,
      previousStatus: OrderStatus.fromString(json['previousStatus'] as String),
      targetStatus: OrderStatus.fromString(json['targetStatus'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      retryCount: (json['retryCount'] as int?) ?? 0,
      note: json['note'] as String?,
    );
  }
}
