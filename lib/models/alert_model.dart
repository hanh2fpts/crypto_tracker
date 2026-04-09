enum AlertCondition { above, below }

class AlertModel {
  final String id;
  final String symbol;
  final String baseAsset;
  final String coinName;
  final double targetPrice;
  final AlertCondition condition;
  bool isActive;
  bool isTriggered;
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.symbol,
    required this.baseAsset,
    required this.coinName,
    required this.targetPrice,
    required this.condition,
    this.isActive = true,
    this.isTriggered = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool shouldTrigger(double currentPrice) {
    if (!isActive || isTriggered) return false;
    return condition == AlertCondition.above
        ? currentPrice >= targetPrice
        : currentPrice <= targetPrice;
  }

  String get conditionText =>
      condition == AlertCondition.above ? 'reaches' : 'drops to';

  String get conditionLabel =>
      condition == AlertCondition.above ? 'ABOVE' : 'BELOW';

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'baseAsset': baseAsset,
        'coinName': coinName,
        'targetPrice': targetPrice,
        'condition': condition.index,
        'isActive': isActive,
        'isTriggered': isTriggered,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
        id: json['id'] as String,
        symbol: json['symbol'] as String,
        baseAsset: json['baseAsset'] as String,
        coinName: json['coinName'] as String,
        targetPrice: (json['targetPrice'] as num).toDouble(),
        condition: AlertCondition.values[json['condition'] as int],
        isActive: json['isActive'] as bool,
        isTriggered: json['isTriggered'] as bool,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      );
}
