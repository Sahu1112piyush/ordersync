import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/order_status.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/order_provider.dart';
import '../widgets/status_badge.dart';

class StatusUpdateScreen extends ConsumerStatefulWidget {
  final String orderId;

  const StatusUpdateScreen({super.key, required this.orderId});

  @override
  ConsumerState<StatusUpdateScreen> createState() => _StatusUpdateScreenState();
}

class _StatusUpdateScreenState extends ConsumerState<StatusUpdateScreen> {
  OrderStatus? _selectedStatus;
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final netState = ref.watch(connectivityProvider);
    final isEffectiveOnline = netState.isEffectiveOnline;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final orderIndex = orderState.orders.indexWhere((o) => o.id == widget.orderId);
    if (orderIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Update Status')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final order = orderState.orders[orderIndex];
    final currentStatus = order.status;

    return Scaffold(
      appBar: AppBar(
        title: Text('Update Status: ${order.id}'),
        actions: [
          TextButton.icon(
            icon: Icon(
              netState.isSimulatedOffline ? Icons.wifi_off : Icons.wifi,
              size: 16,
              color: isEffectiveOnline ? Colors.green : Colors.amber.shade700,
            ),
            label: Text(
              isEffectiveOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 11,
                color: isEffectiveOnline ? Colors.green : Colors.amber.shade700,
              ),
            ),
            onPressed: () {
              ref
                  .read(connectivityProvider.notifier)
                  .toggleSimulatedOffline(!netState.isSimulatedOffline);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Order Status',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentStatus.displayName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    StatusBadge(status: currentStatus),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mode Warning Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEffectiveOnline
                    ? Colors.teal.shade900.withValues(alpha: 0.12)
                    : Colors.amber.shade900.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isEffectiveOnline ? Colors.teal.shade600 : Colors.amber.shade700,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEffectiveOnline ? Icons.cloud_done_rounded : Icons.offline_pin_rounded,
                    color: isEffectiveOnline ? Colors.teal : Colors.amber.shade700,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEffectiveOnline
                          ? 'Online Mode: Status update will sync immediately to mock server.'
                          : 'Offline Mode: Status update will save to local DB and auto-sync when online.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isEffectiveOnline ? Colors.teal : Colors.amber.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Select Target Status Options
            const Text(
              'Select New Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ...OrderStatus.values.map((status) {
              final isCurrent = status == currentStatus;
              final isAllowed = currentStatus.allowedNextStatuses.contains(status);
              final isSelected = _selectedStatus == status;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? status.color : Colors.transparent,
                    width: 2,
                  ),
                ),
                color: isCurrent
                    ? (isDark ? Colors.grey.shade900 : Colors.grey.shade100)
                    : isSelected
                        ? status.color.withValues(alpha: 0.1)
                        : (isDark ? AppColors.surfaceDark : Colors.white),
                child: ListTile(
                  enabled: isAllowed,
                  leading: CircleAvatar(
                    backgroundColor: status.color.withValues(alpha: 0.2),
                    child: Icon(status.icon, color: status.color, size: 20),
                  ),
                  title: Text(
                    status.displayName,
                    style: TextStyle(
                      fontWeight: isSelected || isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Text(
                    isCurrent
                        ? 'Current Status'
                        : isAllowed
                            ? 'Available Next Step'
                            : 'Invalid Transition',
                    style: TextStyle(fontSize: 11, color: isCurrent ? Colors.grey : null),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: status.color)
                      : isAllowed
                          ? const Icon(Icons.chevron_right_rounded)
                          : const Icon(Icons.block_rounded, size: 16, color: Colors.grey),
                  onTap: isAllowed
                      ? () {
                          setState(() {
                            _selectedStatus = status;
                          });
                        }
                      : null,
                ),
              );
            }),
            const SizedBox(height: 16),

            // Note Input Field
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Update Note / Reason (Optional)',
                hintText: 'e.g. Package dispatched via Bluedart AWB-9988',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (_selectedStatus == null || _isSubmitting)
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        setState(() {
                          _isSubmitting = true;
                        });

                        await ref.read(orderProvider.notifier).updateOrderStatus(
                              orderId: widget.orderId,
                              newStatus: _selectedStatus!,
                              note: _noteController.text.trim().isNotEmpty
                                  ? _noteController.text.trim()
                                  : null,
                            );

                        if (mounted) {
                          navigator.pop();
                        }
                      },
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(
                  _isSubmitting
                      ? 'Saving...'
                      : _selectedStatus != null
                          ? 'Confirm Status Change to ${_selectedStatus!.displayName}'
                          : 'Select a Status to Proceed',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
