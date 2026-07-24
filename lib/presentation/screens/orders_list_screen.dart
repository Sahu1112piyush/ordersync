import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/order_status.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/order_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/sync_banner.dart';
import 'order_detail_screen.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final orderNotifier = ref.read(orderProvider.notifier);
    final netState = ref.watch(connectivityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for notification snacks
    ref.listen<OrderState>(orderProvider, (prev, next) {
      if (next.lastSyncNotification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.lastSyncNotification!),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        orderNotifier.clearNotification();
      }
    });

    final filteredOrders = orderState.filteredOrders;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.webp',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sync_alt_rounded, color: AppColors.primary, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'OrderSync',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              netState.isSimulatedOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
              color: netState.isEffectiveOnline ? Colors.green : Colors.amber.shade700,
            ),
            tooltip: netState.isEffectiveOnline ? 'Online' : 'Offline Mode Active',
            onPressed: () {
              ref
                  .read(connectivityProvider.notifier)
                  .toggleSimulatedOffline(!netState.isSimulatedOffline);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sync Orders',
            onPressed: () => orderNotifier.syncPendingQueue(),
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncBanner(),
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => orderNotifier.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search by Order ID, Customer, or Item...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          orderNotifier.setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Status Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip(context, label: 'All', status: null),
                ...OrderStatus.values.map(
                  (s) => _buildFilterChip(context, label: s.displayName, status: s),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Orders List View
          Expanded(
            child: orderState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No orders found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await orderNotifier.syncPendingQueue();
                          await orderNotifier.loadOrders();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];
                            return OrderCard(
                              order: order,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrderDetailScreen(orderId: order.id),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, {required String label, required OrderStatus? status}) {
    final orderState = ref.watch(orderProvider);
    final isSelected = orderState.statusFilter == status;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Colors.white
              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        ),
        selectedColor: AppColors.primary,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        checkmarkColor: Colors.white,
        onSelected: (_) {
          ref.read(orderProvider.notifier).setStatusFilter(status);
        },
      ),
    );
  }
}
