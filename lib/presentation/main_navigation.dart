import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../providers/order_provider.dart';
import 'screens/orders_list_screen.dart';
import 'screens/settings_profile_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    OrdersListScreen(),
    SettingsProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final queueCount = orderState.pendingQueue.length;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: queueCount > 0,
              label: Text('$queueCount'),
              backgroundColor: Colors.amber.shade800,
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: queueCount > 0,
              label: Text('$queueCount'),
              backgroundColor: Colors.amber.shade800,
              child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
            ),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
