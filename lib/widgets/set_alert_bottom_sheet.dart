import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/coin_model.dart';
import '../models/alert_model.dart';
import '../theme/app_theme.dart';

class SetAlertBottomSheet extends StatefulWidget {
  final CoinModel coin;
  const SetAlertBottomSheet({super.key, required this.coin});

  @override
  State<SetAlertBottomSheet> createState() => _SetAlertBottomSheetState();
}

class _SetAlertBottomSheetState extends State<SetAlertBottomSheet>
    with SingleTickerProviderStateMixin {
  AlertCondition _condition = AlertCondition.above;
  final _priceCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _entryCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _priceCtrl.text = widget.coin.formattedPrice;

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final price = double.tryParse(_priceCtrl.text);
    if (price == null) return;
    final alert = AlertModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: widget.coin.symbol,
      baseAsset: widget.coin.baseAsset,
      coinName: widget.coin.name,
      targetPrice: price,
      condition: _condition,
    );
    Navigator.pop(context, alert);
  }

  @override
  Widget build(BuildContext context) {
    final coinColor = AppTheme.coinColor(widget.coin.symbol);

    return SlideTransition(
      position: _slideAnim,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withValues(alpha:0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: const Border(
                top: BorderSide(color: AppTheme.borderMid, width: 0.8),
              ),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 28,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderMid,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Coin header
                  _CoinHeader(coin: widget.coin, coinColor: coinColor),
                  const SizedBox(height: 26),

                  // Condition toggle
                  _ConditionToggle(
                    condition: _condition,
                    onChange: (c) => setState(() => _condition = c),
                  ),
                  const SizedBox(height: 22),

                  // Price input
                  _PriceInput(controller: _priceCtrl),
                  const SizedBox(height: 26),

                  // Submit
                  _SubmitButton(onTap: _submit, condition: _condition),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoinHeader extends StatelessWidget {
  final CoinModel coin;
  final Color coinColor;

  const _CoinHeader({required this.coin, required this.coinColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                coinColor.withValues(alpha:0.25),
                coinColor.withValues(alpha:0.06),
              ],
            ),
            border: Border.all(color: coinColor.withValues(alpha:0.45), width: 1.2),
            boxShadow: [
              BoxShadow(
                  color: coinColor.withValues(alpha:0.25), blurRadius: 14)
            ],
          ),
          child: Center(
            child: Text(
              coin.baseAsset.substring(0, 2),
              style: TextStyle(
                  color: coinColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Alert · ${coin.baseAsset}/USDT',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Text('Now: ',
                    style: TextStyle(
                        color: AppTheme.textMuted, fontSize: 12)),
                ShaderMask(
                  shaderCallback: (b) =>
                      AppTheme.primaryGradient.createShader(b),
                  child: Text(
                    '\$${coin.formattedPrice}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ConditionToggle extends StatelessWidget {
  final AlertCondition condition;
  final void Function(AlertCondition) onChange;

  const _ConditionToggle({required this.condition, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trigger when price',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _CondBtn(
              label: 'RISES ABOVE',
              icon: Icons.trending_up_rounded,
              selected: condition == AlertCondition.above,
              color: AppTheme.priceUp,
              onTap: () => onChange(AlertCondition.above),
            ),
            const SizedBox(width: 10),
            _CondBtn(
              label: 'DROPS BELOW',
              icon: Icons.trending_down_rounded,
              selected: condition == AlertCondition.below,
              color: AppTheme.priceDown,
              onTap: () => onChange(AlertCondition.below),
            ),
          ],
        ),
      ],
    );
  }
}

class _CondBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _CondBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha:0.1) : AppTheme.bgCardAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color.withValues(alpha:0.6) : AppTheme.borderSubtle,
              width: selected ? 1.2 : 0.8,
            ),
            boxShadow: selected
                ? [BoxShadow(color: color.withValues(alpha:0.15), blurRadius: 12)]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? color : AppTheme.textMuted, size: 22),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceInput extends StatelessWidget {
  final TextEditingController controller;
  const _PriceInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Target Price',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: ShaderMask(
                shaderCallback: (b) =>
                    AppTheme.primaryGradient.createShader(b),
                child: const Text(
                  '\$',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            suffixText: 'USDT',
            suffixStyle: const TextStyle(
                color: AppTheme.textMuted, fontSize: 13),
            hintText: '0.00',
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter a price';
            if (double.tryParse(v) == null) return 'Invalid number';
            if (double.parse(v) <= 0) return 'Must be > 0';
            return null;
          },
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final VoidCallback onTap;
  final AlertCondition condition;
  const _SubmitButton({required this.onTap, required this.condition});

  @override
  Widget build(BuildContext context) {
    final isAbove = condition == AlertCondition.above;
    final btnColor = isAbove ? AppTheme.priceUp : AppTheme.priceDown;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isAbove ? AppTheme.upGradient : AppTheme.downGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: btnColor.withValues(alpha:0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAbove
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_active_rounded,
              color: Colors.black,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              isAbove ? 'Alert when price rises' : 'Alert when price drops',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
