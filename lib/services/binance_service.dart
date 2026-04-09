import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class BinanceService {
  static const String _wsBase = 'wss://stream.binance.com:9443/stream';
  static const String _restBase = 'https://api.binance.com/api/v3';

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _tickerController =
      StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  List<String> _symbols = [];
  bool _disposed = false;

  Stream<Map<String, dynamic>> get tickerStream => _tickerController.stream;

  void subscribeToSymbols(List<String> symbols) {
    if (symbols.isEmpty) return;
    _symbols = symbols.map((s) => s.toLowerCase()).toList();
    _connect();
  }

  void _connect() {
    if (_disposed) return;
    _channel?.sink.close();

    final streams = _symbols.map((s) => '$s@ticker').join('/');
    final uri = Uri.parse('$_wsBase?streams=$streams');

    try {
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        (data) {
          if (_disposed) return;
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            final ticker = json['data'] as Map<String, dynamic>;
            _tickerController.add(ticker);
          } catch (_) {}
        },
        onError: (e) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _connect);
  }

  /// Fetch 24hr ticker snapshot via REST (used for initial load & background checks)
  static Future<Map<String, dynamic>?> fetchTicker24h(String symbol) async {
    try {
      final response = await http
          .get(Uri.parse('$_restBase/ticker/24hr?symbol=$symbol'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Fetch kline data for chart
  static Future<List<KlineData>> fetchKlines(
    String symbol, {
    String interval = '1h',
    int limit = 48,
  }) async {
    try {
      final response = await http
          .get(Uri.parse(
              '$_restBase/klines?symbol=$symbol&interval=$interval&limit=$limit'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((k) => KlineData(
                  openTime: k[0] as int,
                  open: double.parse(k[1] as String),
                  high: double.parse(k[2] as String),
                  low: double.parse(k[3] as String),
                  close: double.parse(k[4] as String),
                  volume: double.parse(k[5] as String),
                ))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Fetch all USDT trading pairs for search
  static Future<List<Map<String, String>>> fetchAllUsdtPairs() async {
    try {
      final response = await http
          .get(Uri.parse('$_restBase/exchangeInfo'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final symbols = (data['symbols'] as List)
            .where((s) =>
                s['quoteAsset'] == 'USDT' && s['status'] == 'TRADING')
            .map((s) => {
                  'symbol': s['symbol'] as String,
                  'base': s['baseAsset'] as String,
                  'name': s['baseAsset'] as String,
                })
            .toList();
        return List<Map<String, String>>.from(symbols);
      }
    } catch (_) {}
    return [];
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _tickerController.close();
  }
}

class KlineData {
  final int openTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const KlineData({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  DateTime get time => DateTime.fromMillisecondsSinceEpoch(openTime);
}
