import 'package:flutter/material.dart';

enum OrderStatus {
  pending,
  accepted,
  packed,
  shipped,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.packed:
        return 'Packed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  int get precedenceRank {
    switch (this) {
      case OrderStatus.pending:
        return 1;
      case OrderStatus.accepted:
        return 2;
      case OrderStatus.packed:
        return 3;
      case OrderStatus.shipped:
        return 4;
      case OrderStatus.delivered:
        return 5;
      case OrderStatus.cancelled:
        return 5; // Terminal state equal rank to delivered
    }
  }

  bool get isTerminal => this == OrderStatus.delivered || this == OrderStatus.cancelled;

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.packed:
        return Colors.purple;
      case OrderStatus.shipped:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.hourglass_empty_rounded;
      case OrderStatus.accepted:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.packed:
        return Icons.inventory_2_outlined;
      case OrderStatus.shipped:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.task_alt_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  static OrderStatus fromString(String val) {
    return OrderStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
  }

  List<OrderStatus> get allowedNextStatuses {
    switch (this) {
      case OrderStatus.pending:
        return [OrderStatus.accepted, OrderStatus.cancelled];
      case OrderStatus.accepted:
        return [OrderStatus.packed, OrderStatus.cancelled];
      case OrderStatus.packed:
        return [OrderStatus.shipped, OrderStatus.cancelled];
      case OrderStatus.shipped:
        return [OrderStatus.delivered, OrderStatus.cancelled];
      case OrderStatus.delivered:
        return []; // Terminal state
      case OrderStatus.cancelled:
        return []; // Terminal state
    }
  }
}
