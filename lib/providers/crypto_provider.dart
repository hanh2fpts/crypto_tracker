import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/coin_model.dart';
import '../models/alert_model.dart';
import '../services/binance_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class CryptoProvider extends ChangeNotifier {
  final BinanceService _binanceService = BinanceService();
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();

  final Map<String, CoinModel> _coins = {};
  List<AlertModel> _alerts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  StreamSubscription? _tickerSub;

  // ─── Getters ──────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  List<AlertModel> get alerts => List.unmodifiable(_alerts);

  List<CoinModel> get coins {
    final list = _coins.values.toList();
    list.sort((a, b) => b.price.compareTo(a.price));
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list
        .where((c) =>
            c.symbol.toLowerCase().contains(q) ||
            c.name.toLowerCase().contains(q) ||
            c.baseAsset.toLowerCase().contains(q))
        .toList();
  }

  CoinModel? getCoin(String symbol) => _coins[symbol];

  int get activeAlertsCount => _alerts.where((a) => a.isActive).length;

  // ─── Initialization ───────────────────────────────────────────────────────

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // Load saved coins or use defaults
    final saved = await _storageService.loadWatchedCoins();
    final coinList = saved.isNotEmpty ? saved : kDefaultCoins;

    for (final c in coinList) {
      _coins[c['symbol']!] = CoinModel(
        symbol: c['symbol']!,
        baseAsset: c['base']!,
        name: c['name']!,
      );
    }

    // Load alerts
    _alerts = await _storageService.loadAlerts();

    // Subscribe WebSocket
    _subscribeWebSocket();

    _isLoading = false;
    notifyListeners();
  }

  void _subscribeWebSocket() {
    _tickerSub?.cancel();
    _binanceService.subscribeToSymbols(_coins.keys.toList());

    _tickerSub = _binanceService.tickerStream.listen((ticker) {
      final symbol = ticker['s'] as String?;
      if (symbol == null) return;

      final coin = _coins[symbol];
      if (coin != null) {
        coin.updateFromTicker(ticker);
        _checkAlerts(coin);
        notifyListeners();
      }
    });
  }

  // ─── Alert checking ───────────────────────────────────────────────────────

  void _checkAlerts(CoinModel coin) {
    bool changed = false;
    for (final alert in _alerts) {
      if (alert.symbol != coin.symbol) continue;
      if (alert.shouldTrigger(coin.price)) {
        alert.isTriggered = true;
        alert.isActive = false;
        changed = true;
        _notificationService.showPriceAlert(
          alert: alert,
          currentPrice: coin.price,
        );
      }
    }
    if (changed) {
      _storageService.saveAlerts(_alerts);
    }
  }

  // ─── Watchlist management ─────────────────────────────────────────────────

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  Future<void> addCoin(Map<String, String> coinInfo) async {
    final symbol = coinInfo['symbol']!;
    if (_coins.containsKey(symbol)) return;

    _coins[symbol] = CoinModel(
      symbol: symbol,
      baseAsset: coinInfo['base']!,
      name: coinInfo['name']!,
    );

    await _storageService.saveWatchedCoins(
      _coins.values
          .map((c) => {'symbol': c.symbol, 'base': c.baseAsset, 'name': c.name})
          .toList(),
    );

    // Re-subscribe to include new coin
    _binanceService.subscribeToSymbols(_coins.keys.toList());
    notifyListeners();
  }

  Future<void> removeCoin(String symbol) async {
    _coins.remove(symbol);
    // Also remove related alerts
    _alerts.removeWhere((a) => a.symbol == symbol);
    await _storageService.saveAlerts(_alerts);
    await _storageService.saveWatchedCoins(
      _coins.values
          .map((c) => {'symbol': c.symbol, 'base': c.baseAsset, 'name': c.name})
          .toList(),
    );
    _binanceService.subscribeToSymbols(_coins.keys.toList());
    notifyListeners();
  }

  // ─── Alert management ─────────────────────────────────────────────────────

  Future<void> addAlert(AlertModel alert) async {
    _alerts.add(alert);
    await _storageService.saveAlerts(_alerts);
    notifyListeners();
  }

  Future<void> toggleAlert(String id) async {
    final alert = _alerts.firstWhere((a) => a.id == id);
    alert.isActive = !alert.isActive;
    if (alert.isActive) alert.isTriggered = false;
    await _storageService.saveAlerts(_alerts);
    notifyListeners();
  }

  Future<void> deleteAlert(String id) async {
    _alerts.removeWhere((a) => a.id == id);
    await _storageService.saveAlerts(_alerts);
    notifyListeners();
  }

  Future<void> clearTriggeredAlerts() async {
    _alerts.removeWhere((a) => a.isTriggered);
    await _storageService.saveAlerts(_alerts);
    notifyListeners();
  }

  List<AlertModel> getAlertsForCoin(String symbol) =>
      _alerts.where((a) => a.symbol == symbol).toList();

  @override
  void dispose() {
    _tickerSub?.cancel();
    _binanceService.dispose();
    super.dispose();
  }
}
