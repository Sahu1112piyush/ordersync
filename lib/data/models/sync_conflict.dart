import 'order_status.dart';

class SyncConflictLog {
  final String id;
  final String orderId;
  final String customerName;
  final OrderStatus serverStatus;
  final OrderStatus clientStatus;
  final OrderStatus resolvedStatus;
  final String resolutionStrategy; // e.g. 'Terminal Precedence Rule', 'Timestamp Matrix'
  final DateTime timestamp;

  const SyncConflictLog({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.serverStatus,
    required this.clientStatus,
    required this.resolvedStatus,
    required this.resolutionStrategy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'customerName': customerName,
      'serverStatus': serverStatus.name,
      'clientStatus': clientStatus.name,
      'resolvedStatus': resolvedStatus.name,
      'resolutionStrategy': resolutionStrategy,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SyncConflictLog.fromJson(Map<String, dynamic> json) {
    return SyncConflictLog(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      customerName: json['customerName'] as String,
      serverStatus: OrderStatus.fromString(json['serverStatus'] as String),
      clientStatus: OrderStatus.fromString(json['clientStatus'] as String),
      resolvedStatus: OrderStatus.fromString(json['resolvedStatus'] as String),
      resolutionStrategy: json['resolutionStrategy'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
