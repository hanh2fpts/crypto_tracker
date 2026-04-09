import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/binance_service.dart';
import 'app.dart';

/// Background task identifier
const String kPriceCheckTask = 'com.strade.crypto_tracker.price_check';

/// Workmanager callback — must be a top-level function.
/// Called by the OS when background task is executed.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == kPriceCheckTask) {
      await _backgroundPriceCheck();
    }
    return Future.value(true);
  });
}

Future<void> _backgroundPriceCheck() async {
  final storage = StorageService();
  final notifications = NotificationService();

  // Init notifications for background context
  await notifications.init();

  final alerts = await storage.loadAlerts();
  final activeAlerts = alerts.where((a) => a.isActive && !a.isTriggered);

  if (activeAlerts.isEmpty) return;

  // Group by symbol to avoid duplicate REST calls
  final symbolsToCheck = activeAlerts.map((a) => a.symbol).toSet();

  bool changed = false;
  for (final symbol in symbolsToCheck) {
    final ticker = await BinanceService.fetchTicker24h(symbol);
    if (ticker == null) continue;

    final currentPrice =
        double.tryParse(ticker['lastPrice'] ?? ticker['c'] ?? '0') ?? 0;
    if (currentPrice <= 0) continue;

    for (final alert in activeAlerts.where((a) => a.symbol == symbol)) {
      if (alert.shouldTrigger(currentPrice)) {
        alert.isTriggered = true;
        alert.isActive = false;
        changed = true;
        await notifications.showPriceAlert(
          alert: alert,
          currentPrice: currentPrice,
        );
      }
    }
  }

  if (changed) {
    await storage.saveAlerts(alerts);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermission();

  // Initialize background task runner
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Register periodic background price check (min interval: 15min on Android)
  await Workmanager().registerPeriodicTask(
    kPriceCheckTask,
    kPriceCheckTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  runApp(const CryptoTrackerApp());
}
