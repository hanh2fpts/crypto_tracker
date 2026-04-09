import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/coin_model.dart';
import '../theme/app_theme.dart';
import 'animated_price.dart';

class CoinTile extends StatelessWidget {
  final CoinModel coin;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const CoinTile({
    super.key,
    required this.coin,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = coin.isPositive;
    final changeColor = isUp ? AppTheme.priceUp : AppTheme.priceDown;
    final coinColor = AppTheme.coinColor(coin.symbol);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Avatar with glow ─────────────────────────────────────────
            _CoinAvatar(coinColor: coinColor, baseAsset: coin.baseAsset),
            const SizedBox(width: 12),

            // ── Name + volume ─────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.baseAsset,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    coin.name,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // ── Sparkline ─────────────────────────────────────────────────
            if (coin.priceHistory.length >= 3)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _Sparkline(
                  prices: [...coin.priceHistory, coin.price],
                  color: changeColor,
                  width: 64,
                  height: 32,
                ),
              )
            else
              const SizedBox(width: 10),

            // ── Price + badge ─────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedPriceText(
                  price: '\$${coin.formattedPrice}',
                  isPositive: isUp,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                _ChangeBadge(text: coin.formattedChange, color: changeColor, isUp: isUp),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Coin Avatar ─────────────────────────────────────────────────────────────

class _CoinAvatar extends StatelessWidget {
  final Color coinColor;
  final String baseAsset;

  const _CoinAvatar({required this.coinColor, required this.baseAsset});

  @override
  Widget build(BuildContext context) {
    final label = baseAsset.length >= 2 ? baseAsset.substring(0, 2) : baseAsset;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.2,
          colors: [
            coinColor.withOpacity(0.22),
            coinColor.withOpacity(0.06),
          ],
        ),
        border: Border.all(color: coinColor.withOpacity(0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: coinColor.withOpacity(0.25),
            blurRadius: 14,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: coinColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ─── Change Badge ────────────────────────────────────────────────────────────

class _ChangeBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool isUp;

  const _ChangeBadge({required this.text, required this.color, required this.isUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
            color: color,
            size: 13,
          ),
          Text(
            text.replaceAll('+', '').replaceAll('-', ''),
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sparkline ───────────────────────────────────────────────────────────────

class _Sparkline extends StatelessWidget {
  final List<double> prices;
  final Color color;
  final double width;
  final double height;

  const _Sparkline({
    required this.prices,
    required this.color,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _SparklinePainter(prices: prices, color: color),
        ),
      );
}

class _SparklinePainter extends CustomPainter {
  final List<double> prices;
  final Color color;

  _SparklinePainter({required this.prices, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;

    final min = prices.reduce(math.min);
    final max = prices.reduce(math.max);
    final range = max - min;
    if (range == 0) return;

    final pts = <Offset>[];
    for (int i = 0; i < prices.length; i++) {
      final x = i / (prices.length - 1) * size.width;
      final y = size.height - ((prices[i] - min) / range) * size.height * 0.85;
      pts.add(Offset(x, y));
    }

    // Smooth bezier path
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
    }

    // Glow layer
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.18)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Main line
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Gradient fill
    final fillPath = Path.from(path)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.28), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.prices.length != prices.length ||
      (prices.isNotEmpty &&
          old.prices.isNotEmpty &&
          old.prices.last != prices.last);
}
