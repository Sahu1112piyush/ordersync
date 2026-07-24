import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/local_storage_service.dart';

class NetworkState {
  final bool isPhysicalOnline;
  final bool isSimulatedOffline;

  const NetworkState({
    required this.isPhysicalOnline,
    required this.isSimulatedOffline,
  });

  bool get isEffectiveOnline => isPhysicalOnline && !isSimulatedOffline;

  NetworkState copyWith({
    bool? isPhysicalOnline,
    bool? isSimulatedOffline,
  }) {
    return NetworkState(
      isPhysicalOnline: isPhysicalOnline ?? this.isPhysicalOnline,
      isSimulatedOffline: isSimulatedOffline ?? this.isSimulatedOffline,
    );
  }
}

class ConnectivityNotifier extends Notifier<NetworkState> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  NetworkState build() {
    final localStorage = ref.watch(localStorageServiceProvider);
    _init();
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return NetworkState(
      isPhysicalOnline: true,
      isSimulatedOffline: localStorage.isSimulatedOffline(),
    );
  }

  void _init() async {
    final initialResults = await Connectivity().checkConnectivity();
    _updateConnectivity(initialResults);

    _subscription = Connectivity().onConnectivityChanged.listen(_updateConnectivity);
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final isOnline = !results.contains(ConnectivityResult.none);
    state = state.copyWith(isPhysicalOnline: isOnline);
  }

  Future<void> toggleSimulatedOffline(bool value) async {
    final localStorage = ref.read(localStorageServiceProvider);
    await localStorage.setSimulatedOffline(value);
    state = state.copyWith(isSimulatedOffline: value);
  }
}

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final connectivityProvider = NotifierProvider<ConnectivityNotifier, NetworkState>(
  ConnectivityNotifier.new,
);
