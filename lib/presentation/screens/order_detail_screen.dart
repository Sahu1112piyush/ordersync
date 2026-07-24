import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/order.dart';
import '../../data/models/order_status.dart';
import '../../providers/order_provider.dart';
import '../widgets/status_badge.dart';
import 'status_update_screen.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
    final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

    final orderIndex = orderState.orders.indexWhere((o) => o.id == orderId);
    if (orderIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final order = orderState.orders[orderIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(order.id),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'Order ${order.id} - Customer: ${order.customerName}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order details copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Conflict Banner
            if (order.syncState == SyncState.pendingSync)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.offline_pin_rounded, color: Colors.amber),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Offline Change Pending: This update is stored locally and will sync once online.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber),
                      ),
                    ),
                  ],
                ),
              )
            else if (order.syncState == SyncState.conflict)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade900.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade800),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Conflict Resolved: ${order.lastConflictReason ?? "Status updated by rule matrix."}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

            // Header Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Status',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        StatusBadge(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Order Placed: ${dateFormatter.format(order.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Customer Info Card
            const Text('Customer Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      icon: Icons.person_rounded,
                      title: 'Customer Name',
                      value: order.customerName,
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      context,
                      icon: Icons.phone_rounded,
                      title: 'Phone Number',
                      value: order.phone,
                      trailing: IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: order.phone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Phone number copied')),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      context,
                      icon: Icons.location_on_rounded,
                      title: 'Delivery Address',
                      value: order.address,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ordered Products Card
            const Text('Ordered Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      'Qty: ${item.quantity} × ${currencyFormatter.format(item.unitPrice)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                currencyFormatter.format(item.totalPrice),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        )),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Status', style: TextStyle(fontWeight: FontWeight.w600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.paymentStatus,
                            style: const TextStyle(
                                color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          currencyFormatter.format(order.totalAmount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Workflow Timeline Stepper
            const Text('Workflow Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTimelineStep(context, status: OrderStatus.pending, currentStatus: order.status),
                    _buildTimelineStep(context, status: OrderStatus.accepted, currentStatus: order.status),
                    _buildTimelineStep(context, status: OrderStatus.packed, currentStatus: order.status),
                    _buildTimelineStep(context, status: OrderStatus.shipped, currentStatus: order.status),
                    _buildTimelineStep(context,
                        status: OrderStatus.delivered, currentStatus: order.status, isLast: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80), // Bottom padding for FAB/Button
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: order.status.isTerminal
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatusUpdateScreen(orderId: order.id),
                      ),
                    );
                  },
            icon: const Icon(Icons.edit_note_rounded),
            label: Text(
              order.status.isTerminal
                  ? 'Order is ${order.status.displayName} (Terminal)'
                  : 'Update Order Status',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon, required String title, required String value, Widget? trailing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        // ignore: use_null_aware_elements
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildTimelineStep(BuildContext context,
      {required OrderStatus status, required OrderStatus currentStatus, bool isLast = false}) {
    final isCompleted = currentStatus.precedenceRank >= status.precedenceRank &&
        currentStatus != OrderStatus.cancelled;
    final isCurrent = currentStatus == status;

    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent
                    ? status.color
                    : isCompleted
                        ? status.color.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.3),
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.circle,
                size: 14,
                color: isCurrent || isCompleted ? Colors.white : Colors.transparent,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: isCompleted ? status.color.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            status.displayName,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? status.color : null,
            ),
          ),
        ),
      ],
    );
  }
}
