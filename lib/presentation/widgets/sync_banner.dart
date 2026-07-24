import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/order_provider.dart';

class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netState = ref.watch(connectivityProvider);
    final orderState = ref.watch(orderProvider);
    final queueCount = orderState.pendingQueue.length;
    final isEffectiveOnline = netState.isEffectiveOnline;

    if (isEffectiveOnline && queueCount == 0 && !orderState.isSyncing) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    IconData iconData;
    String text;

    if (!isEffectiveOnline) {
      bgColor = Colors.amber.shade900;
      iconData = Icons.wifi_off_rounded;
      text = netState.isSimulatedOffline
          ? 'Simulated Offline Mode Active • $queueCount pending offline updates'
          : 'No Network Connection • $queueCount pending offline updates';
    } else if (orderState.isSyncing) {
      bgColor = Colors.indigo.shade800;
      iconData = Icons.sync_rounded;
      text = 'Syncing $queueCount pending updates to server...';
    } else {
      bgColor = Colors.teal.shade800;
      iconData = Icons.cloud_queue_rounded;
      text = '$queueCount pending updates ready to sync';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          children: [
            if (orderState.isSyncing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(iconData, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isEffectiveOnline && queueCount > 0 && !orderState.isSyncing)
              ElevatedButton(
                onPressed: () => ref.read(orderProvider.notifier).syncPendingQueue(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.teal.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Sync Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
