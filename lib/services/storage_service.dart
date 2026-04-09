import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_model.dart';

class StorageService {
  static const String _alertsKey = 'price_alerts';
  static const String _watchedCoinsKey = 'watched_coins';

  // ─── Alerts ───────────────────────────────────────────────────────────────

  Future<List<AlertModel>> loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_alertsKey) ?? [];
    return raw
        .map((s) {
          try {
            return AlertModel.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<AlertModel>()
        .toList();
  }

  Future<void> saveAlerts(List<AlertModel> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = alerts.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_alertsKey, raw);
  }

  Future<void> addAlert(AlertModel alert) async {
    final alerts = await loadAlerts();
    alerts.add(alert);
    await saveAlerts(alerts);
  }

  Future<void> updateAlert(AlertModel updated) async {
    final alerts = await loadAlerts();
    final idx = alerts.indexWhere((a) => a.id == updated.id);
    if (idx != -1) {
      alerts[idx] = updated;
      await saveAlerts(alerts);
    }
  }

  Future<void> deleteAlert(String id) async {
    final alerts = await loadAlerts();
    alerts.removeWhere((a) => a.id == id);
    await saveAlerts(alerts);
  }

  // ─── Watched Coins ────────────────────────────────────────────────────────

  Future<List<Map<String, String>>> loadWatchedCoins() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_watchedCoinsKey);
    if (raw == null) return [];
    return raw
        .map((s) {
          try {
            return Map<String, String>.from(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, String>>()
        .toList();
  }

  Future<void> saveWatchedCoins(List<Map<String, String>> coins) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = coins.map((c) => jsonEncode(c)).toList();
    await prefs.setStringList(_watchedCoinsKey, raw);
  }
}
