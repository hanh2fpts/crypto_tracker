import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Flashes green or red when price updates, then smoothly fades back to white.
class AnimatedPriceText extends StatefulWidget {
  final String price;
  final bool isPositive;
  final TextStyle style;

  const AnimatedPriceText({
    super.key,
    required this.price,
    required this.isPositive,
    required this.style,
  });

  @override
  State<AnimatedPriceText> createState() => _AnimatedPriceTextState();
}

class _AnimatedPriceTextState extends State<AnimatedPriceText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  Animation<Color?>? _colorAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void didUpdateWidget(AnimatedPriceText old) {
    super.didUpdateWidget(old);
    if (old.price != widget.price) {
      final flash =
          widget.isPositive ? AppTheme.priceUp : AppTheme.priceDown;
      final target = widget.style.color ?? AppTheme.textPrimary;
      _colorAnim = ColorTween(begin: flash, end: target)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final col = (_ctrl.isAnimating && _colorAnim != null)
            ? _colorAnim!.value
            : widget.style.color;
        return Text(widget.price, style: widget.style.copyWith(color: col));
      },
    );
  }
}
