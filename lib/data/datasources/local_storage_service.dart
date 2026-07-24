import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/sync_action.dart';
import '../models/sync_conflict.dart';

class LocalStorageService {
  static const String _ordersKey = 'ordersync_cached_orders';
  static const String _queueKey = 'ordersync_action_queue';
  static const String _conflictsKey = 'ordersync_conflict_logs';
  static const String _darkModeKey = 'ordersync_dark_mode';
  static const String _offlineModeKey = 'ordersync_simulated_offline';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Orders Cache ---
  Future<void> saveOrders(List<OrderModel> orders) async {
    final rawJson = jsonEncode(orders.map((o) => o.toJson()).toList());
    await _prefs.setString(_ordersKey, rawJson);
  }

  List<OrderModel> getOrders() {
    final rawJson = _prefs.getString(_ordersKey);
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final List decoded = jsonDecode(rawJson);
      return decoded.map((item) => OrderModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Sync Queue ---
  Future<void> saveSyncQueue(List<SyncAction> queue) async {
    final rawJson = jsonEncode(queue.map((a) => a.toJson()).toList());
    await _prefs.setString(_queueKey, rawJson);
  }

  List<SyncAction> getSyncQueue() {
    final rawJson = _prefs.getString(_queueKey);
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final List decoded = jsonDecode(rawJson);
      return decoded.map((item) => SyncAction.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Conflict Logs ---
  Future<void> saveConflictLogs(List<SyncConflictLog> logs) async {
    final rawJson = jsonEncode(logs.map((l) => l.toJson()).toList());
    await _prefs.setString(_conflictsKey, rawJson);
  }

  List<SyncConflictLog> getConflictLogs() {
    final rawJson = _prefs.getString(_conflictsKey);
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final List decoded = jsonDecode(rawJson);
      return decoded.map((item) => SyncConflictLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Theme & Settings ---
  bool isDarkMode() => _prefs.getBool(_darkModeKey) ?? false;
  Future<void> setDarkMode(bool value) async => await _prefs.setBool(_darkModeKey, value);

  bool isSimulatedOffline() => _prefs.getBool(_offlineModeKey) ?? false;
  Future<void> setSimulatedOffline(bool value) async => await _prefs.setBool(_offlineModeKey, value);
}
