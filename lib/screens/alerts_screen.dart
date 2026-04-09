import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';
import '../providers/crypto_provider.dart';
import '../theme/app_theme.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: AppTheme.bgPrimary.withValues(alpha:0.7),
              title: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (b) =>
                        AppTheme.primaryGradient.createShader(b),
                    child: const Icon(Icons.notifications_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text('Price Alerts'),
                ],
              ),
              actions: [
                Consumer<CryptoProvider>(
                  builder: (_, p, __) {
                    final has = p.alerts.any((a) => a.isTriggered);
                    if (!has) return const SizedBox.shrink();
                    return TextButton.icon(
                      onPressed: p.clearTriggeredAlerts,
                      icon: const Icon(Icons.rounded_corner,
                          size: 14, color: AppTheme.textMuted),
                      label: const Text(
                        'Clear',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 12),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<CryptoProvider>(
        builder: (_, provider, __) {
          final alerts = provider.alerts;

          return alerts.isEmpty
              ? _EmptyState()
              : _AlertList(provider: provider, alerts: alerts);
        },
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated ring icon
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentTeal.withValues(alpha:0.15),
                  AppTheme.accentTeal.withValues(alpha:0.03),
                ],
              ),
              border: Border.all(
                  color: AppTheme.accentTeal.withValues(alpha:0.25), width: 1.5),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppTheme.accentTeal,
              size: 36,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'No Alerts Yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Open a coin and tap "Set Alert"\nto get notified when price moves.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Alert List ───────────────────────────────────────────────────────────────

class _AlertList extends StatelessWidget {
  final CryptoProvider provider;
  final List<AlertModel> alerts;

  const _AlertList({required this.provider, required this.alerts});

  @override
  Widget build(BuildContext context) {
    // Group by coin symbol
    final grouped = <String, List<AlertModel>>{};
    for (final a in alerts) {
      grouped.putIfAbsent(a.symbol, () => []).add(a);
    }

    final active = alerts.where((a) => a.isActive).length;
    final triggered = alerts.where((a) => a.isTriggered).length;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 90)),

        // Summary strip
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _SummaryStrip(
              total: alerts.length,
              active: active,
              triggered: triggered,
            ),
          ),
        ),

        // Coin groups
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final entry = grouped.entries.toList()[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _CoinAlertGroup(
                    symbol: entry.key,
                    alerts: entry.value,
                    currentPrice:
                        provider.getCoin(entry.key)?.price ?? 0,
                    onToggle: provider.toggleAlert,
                    onDelete: provider.deleteAlert,
                  ),
                );
              },
              childCount: grouped.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Summary Strip ────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final int total;
  final int active;
  final int triggered;

  const _SummaryStrip({
    required this.total,
    required this.active,
    required this.triggered,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SChip(label: 'Total', count: total, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        _SChip(label: 'Active', count: active, color: AppTheme.accentTeal),
        const SizedBox(width: 8),
        _SChip(
            label: 'Triggered', count: triggered, color: AppTheme.accentBlue),
      ],
    );
  }
}

class _SChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.2), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Coin Alert Group ─────────────────────────────────────────────────────────

class _CoinAlertGroup extends StatelessWidget {
  final String symbol;
  final List<AlertModel> alerts;
  final double currentPrice;
  final void Function(String) onToggle;
  final void Function(String) onDelete;

  const _CoinAlertGroup({
    required this.symbol,
    required this.alerts,
    required this.currentPrice,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final coinColor = AppTheme.coinColor(symbol);
    final base = alerts.first.baseAsset;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha:0.2), blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        coinColor.withValues(alpha:0.22),
                        coinColor.withValues(alpha:0.05),
                      ],
                    ),
                    border: Border.all(
                        color: coinColor.withValues(alpha:0.4), width: 1),
                    boxShadow: [
                      BoxShadow(
                          color: coinColor.withValues(alpha:0.2), blurRadius: 8)
                    ],
                  ),
                  child: Center(
                    child: Text(
                      base.length >= 2 ? base.substring(0, 2) : base,
                      style: TextStyle(
                        color: coinColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(base,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        )),
                    if (currentPrice > 0)
                      Text(
                        'Now: \$${_fmt(currentPrice)}',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11),
                      ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCardAlt,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${alerts.length}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Container(
              height: 0.5, color: AppTheme.borderSubtle),

          // Alert items
          ...alerts.asMap().entries.map((e) {
            final isLast = e.key == alerts.length - 1;
            return Column(
              children: [
                _AlertRow(
                  alert: e.value,
                  onToggle: () => onToggle(e.value.id),
                  onDelete: () => _confirmDelete(
                      context, e.value.id, onDelete),
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(height: 0.5, color: AppTheme.borderSubtle),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id,
      void Function(String) onDelete) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.priceDown, size: 32),
              const SizedBox(height: 14),
              const Text('Delete this alert?',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderMid),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel',
                          style:
                              TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        onDelete(id);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppTheme.priceDown.withValues(alpha:0.15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Delete',
                          style: TextStyle(
                              color: AppTheme.priceDown,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000) return v.toStringAsFixed(2);
    if (v >= 1) return v.toStringAsFixed(4);
    return v.toStringAsFixed(6);
  }
}

// ─── Alert Row ────────────────────────────────────────────────────────────────

class _AlertRow extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _AlertRow({
    required this.alert,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAbove = alert.condition == AlertCondition.above;
    final condColor = isAbove ? AppTheme.priceUp : AppTheme.priceDown;

    // Status
    final Color statusColor;
    final String statusLabel;
    if (alert.isTriggered) {
      statusColor = AppTheme.accentBlue;
      statusLabel = 'TRIGGERED';
    } else if (alert.isActive) {
      statusColor = condColor;
      statusLabel = 'ACTIVE';
    } else {
      statusColor = AppTheme.textMuted;
      statusLabel = 'PAUSED';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Direction icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: condColor.withValues(alpha:0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: condColor.withValues(alpha:0.2), width: 0.8),
            ),
            child: Icon(
              isAbove
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: condColor,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),

          // Price + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${isAbove ? '≥' : '≤'} \$${_fmt(alert.targetPrice)}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha:0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, HH:mm').format(alert.createdAt),
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),

          // Toggle switch
          if (!alert.isTriggered)
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: alert.isActive
                      ? AppTheme.accentTeal.withValues(alpha:0.2)
                      : AppTheme.bgCardAlt,
                  border: Border.all(
                    color: alert.isActive
                        ? AppTheme.accentTeal.withValues(alpha:0.6)
                        : AppTheme.borderSubtle,
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      alignment: alert.isActive
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: alert.isActive
                              ? AppTheme.accentTeal
                              : AppTheme.textMuted,
                          boxShadow: alert.isActive
                              ? [
                                  BoxShadow(
                                    color: AppTheme.accentTeal.withValues(alpha:0.6),
                                    blurRadius: 6,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(width: 8),

          // Delete
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.bgCardAlt,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.textMuted, size: 15),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000) return v.toStringAsFixed(2);
    if (v >= 1) return v.toStringAsFixed(4);
    return v.toStringAsFixed(6);
  }
}
