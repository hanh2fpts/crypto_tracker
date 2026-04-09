class CoinModel {
  final String symbol;
  final String baseAsset;
  final String name;
  double price;
  double priceChange;
  double priceChangePercent;
  double highPrice;
  double lowPrice;
  double volume;
  List<double> priceHistory; // last N prices for sparkline

  CoinModel({
    required this.symbol,
    required this.baseAsset,
    required this.name,
    this.price = 0.0,
    this.priceChange = 0.0,
    this.priceChangePercent = 0.0,
    this.highPrice = 0.0,
    this.lowPrice = 0.0,
    this.volume = 0.0,
    List<double>? priceHistory,
  }) : priceHistory = priceHistory ?? [];

  void updateFromTicker(Map<String, dynamic> ticker) {
    final newPrice = double.tryParse(ticker['c'] ?? '0') ?? 0;
    if (price > 0 && newPrice != price) {
      priceHistory.add(price);
      if (priceHistory.length > 30) priceHistory.removeAt(0);
    }
    price = newPrice;
    priceChange = double.tryParse(ticker['p'] ?? '0') ?? 0;
    priceChangePercent = double.tryParse(ticker['P'] ?? '0') ?? 0;
    highPrice = double.tryParse(ticker['h'] ?? '0') ?? 0;
    lowPrice = double.tryParse(ticker['l'] ?? '0') ?? 0;
    volume = double.tryParse(ticker['v'] ?? '0') ?? 0;
  }

  bool get isPositive => priceChangePercent >= 0;

  String get formattedPrice {
    if (price >= 1000) return price.toStringAsFixed(2);
    if (price >= 1) return price.toStringAsFixed(4);
    if (price >= 0.01) return price.toStringAsFixed(5);
    return price.toStringAsFixed(8);
  }

  String get formattedChange =>
      '${isPositive ? '+' : ''}${priceChangePercent.toStringAsFixed(2)}%';
}

// Default coin list
const List<Map<String, String>> kDefaultCoins = [
  {'symbol': 'BTCUSDT', 'base': 'BTC', 'name': 'Bitcoin'},
  {'symbol': 'ETHUSDT', 'base': 'ETH', 'name': 'Ethereum'},
  {'symbol': 'BNBUSDT', 'base': 'BNB', 'name': 'BNB'},
  {'symbol': 'SOLUSDT', 'base': 'SOL', 'name': 'Solana'},
  {'symbol': 'XRPUSDT', 'base': 'XRP', 'name': 'XRP'},
  {'symbol': 'ADAUSDT', 'base': 'ADA', 'name': 'Cardano'},
  {'symbol': 'DOGEUSDT', 'base': 'DOGE', 'name': 'Dogecoin'},
  {'symbol': 'AVAXUSDT', 'base': 'AVAX', 'name': 'Avalanche'},
  {'symbol': 'DOTUSDT', 'base': 'DOT', 'name': 'Polkadot'},
  {'symbol': 'LINKUSDT', 'base': 'LINK', 'name': 'Chainlink'},
  {'symbol': 'MATICUSDT', 'base': 'MATIC', 'name': 'Polygon'},
  {'symbol': 'LTCUSDT', 'base': 'LTC', 'name': 'Litecoin'},
];
