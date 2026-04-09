import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/coin_model.dart';
import '../models/alert_model.dart';
import '../providers/crypto_provider.dart';
import '../services/binance_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_price.dart';
import '../widgets/set_alert_bottom_sheet.dart';

class CoinDetailScreen extends StatefulWidget {
  final String symbol;
  const CoinDetailScreen({super.key, required this.symbol});

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen>
    with SingleTickerProviderStateMixin {
  List<KlineData> _klines = [];
  String _interval = '1h';
  bool _chartLoading = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _intervals = [
    ('15m', '15m'),
    ('1h', '1H'),
    ('4h', '4H'),
    ('1d', '1D'),
    ('1w', '1W'),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _loadChart();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChart() async {
    setState(() => _chartLoading = true);
    _fadeCtrl.reset();
    final data = await BinanceService.fetchKlines(
      widget.symbol,
      interval: _interval,
      limit: 60,
    );
    if (mounted) {
      setState(() {
        _klines = data;
        _chartLoading = false;
      });
      _fadeCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CryptoProvider>(
      builder: (_, provider, __) {
        final coin = provider.getCoin(widget.symbol);
        if (coin == null) return const SizedBox.shrink();
        return _buildScaffold(context, provider, coin);
      },
    );
  }

  Widget _buildScaffold(
      BuildContext context, CryptoProvider provider, CoinModel coin) {
    final isUp = coin.isPositive;
    final priceColor = isUp ? AppTheme.priceUp : AppTheme.priceDown;
    final coinColor = AppTheme.coinColor(coin.symbol);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── Ambient background glow ─────────────────────────────────────
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    coinColor.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ────────────────────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, provider, coin, coinColor),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price hero
                      _PriceHero(coin: coin, priceColor: priceColor, isUp: isUp),
                      const SizedBox(height: 28),

                      // Interval picker
                      _IntervalRow(
                        intervals: _intervals,
                        selected: _interval,
                        onSelect: (v) {
                          setState(() => _interval = v);
                          _loadChart();
                        },
                      ),
                      const SizedBox(height: 14),

                      // Chart
                      _ChartContainer(
                        klines: _klines,
                        loading: _chartLoading,
                        fadeAnim: _fadeAnim,
                        lineColor: priceColor,
                        interval: _interval,
                      ),
                      const SizedBox(height: 24),

                      // Stats grid
                      _StatsGrid(coin: coin),
                      const SizedBox(height: 28),

                      // Alerts section
                      _AlertsSection(
                        symbol: coin.symbol,
                        provider: provider,
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      // ── Set alert FAB ────────────────────────────────────────────────────
      floatingActionButton: _SetAlertFab(
        coin: coin,
        onAlertCreated: (alert) async {
          await provider.addAlert(alert);
          if (context.mounted) {
            _showSnackbar(context,
                '${alert.baseAsset} alert set at \$${alert.targetPrice}');
          }
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, CryptoProvider provider,
      CoinModel coin, Color coinColor) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 0,
      pinned: true,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: AppTheme.bgPrimary.withOpacity(0.75),
          ),
        ),
      ),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 15, color: AppTheme.textSecondary),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: coinColor.withOpacity(0.18),
              border: Border.all(color: coinColor.withOpacity(0.4), width: 1),
              boxShadow: [
                BoxShadow(
                    color: coinColor.withOpacity(0.2), blurRadius: 8)
              ],
            ),
            child: Center(
              child: Text(
                coin.baseAsset.substring(0, 2),
                style: TextStyle(
                    color: coinColor, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(coin.baseAsset,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(width: 4),
          const Text('/USDT',
              style: TextStyle(
                  color: AppTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
      backgroundColor: AppTheme.bgCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      margin: const EdgeInsets.all(16),
    ));
  }
}

// ─── Price Hero ───────────────────────────────────────────────────────────────

class _PriceHero extends StatelessWidget {
  final CoinModel coin;
  final Color priceColor;
  final bool isUp;

  const _PriceHero(
      {required this.coin, required this.priceColor, required this.isUp});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedPriceText(
          price: '\$${coin.formattedPrice}',
          isPositive: isUp,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 38,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: priceColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: priceColor.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(
                    isUp
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: priceColor,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    coin.formattedChange,
                    style: TextStyle(
                      color: priceColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '24h change',
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Interval Row ─────────────────────────────────────────────────────────────

class _IntervalRow extends StatelessWidget {
  final List<(String, String)> intervals;
  final String selected;
  final void Function(String) onSelect;

  const _IntervalRow({
    required this.intervals,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: intervals.map((t) {
        final (val, label) = t;
        final active = val == selected;
        return GestureDetector(
          onTap: () => onSelect(val),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: active ? AppTheme.primaryGradient : null,
              color: active ? null : AppTheme.bgCardAlt,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? Colors.transparent
                    : AppTheme.borderSubtle,
                width: 0.8,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppTheme.accentTeal.withOpacity(0.3),
                        blurRadius: 12,
                      )
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.black : AppTheme.textMuted,
                fontSize: 12,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Chart Container ──────────────────────────────────────────────────────────

class _ChartContainer extends StatelessWidget {
  final List<KlineData> klines;
  final bool loading;
  final Animation<double> fadeAnim;
  final Color lineColor;
  final String interval;

  const _ChartContainer({
    required this.klines,
    required this.loading,
    required this.fadeAnim,
    required this.lineColor,
    required this.interval,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 12, right: 4, bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
      ),
      child: loading
          ? Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation(lineColor.withOpacity(0.7)),
                ),
              ),
            )
          : klines.isEmpty
              ? const Center(
                  child: Text('No data',
                      style: TextStyle(color: AppTheme.textMuted)),
                )
              : FadeTransition(
                  opacity: fadeAnim,
                  child: _buildChart(),
                ),
    );
  }

  Widget _buildChart() {
    final spots = klines.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.close))
        .toList();

    final prices = klines.map((k) => k.close).toList();
    final minY = prices.reduce((a, b) => a < b ? a : b) * 0.9985;
    final maxY = prices.reduce((a, b) => a > b ? a : b) * 1.0015;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppTheme.borderSubtle,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              interval: (maxY - minY) / 3,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _fmtAxis(v),
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 9.5),
                ),
              ),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (klines.length / 4).roundToDouble(),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= klines.length) return const SizedBox.shrink();
                final t = klines[i].time;
                final label = interval.contains('d') || interval.contains('w')
                    ? DateFormat('MM/dd').format(t)
                    : DateFormat('HH:mm').format(t);
                return Text(label,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 9.5));
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: lineColor,
            barWidth: 1.8,
            dotData: const FlDotData(show: false),
            shadow: Shadow(color: lineColor.withOpacity(0.25), blurRadius: 8),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withOpacity(0.22),
                  lineColor.withOpacity(0.04),
                  lineColor.withOpacity(0.0),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppTheme.bgCardAlt,
            tooltipBorder:
                const BorderSide(color: AppTheme.borderMid, width: 0.8),
            tooltipRoundedRadius: 10,
            getTooltipItems: (spots) => spots.map((s) {
              final i = s.x.toInt();
              final time = i < klines.length
                  ? DateFormat('HH:mm dd/MM').format(klines[i].time)
                  : '';
              return LineTooltipItem(
                '\$${_fmtPrice(s.y)}\n',
                TextStyle(
                  color: lineColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(
                    text: time,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _fmtAxis(double v) {
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
    if (v >= 1) return '\$${v.toStringAsFixed(2)}';
    return '\$${v.toStringAsFixed(4)}';
  }

  String _fmtPrice(double v) {
    if (v >= 1000) return v.toStringAsFixed(2);
    if (v >= 1) return v.toStringAsFixed(4);
    return v.toStringAsFixed(6);
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final CoinModel coin;
  const _StatsGrid({required this.coin});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: '24h High',
                value: '\$${_fmt(coin.highPrice)}',
                color: AppTheme.priceUp,
                icon: Icons.arrow_upward_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: '24h Low',
                value: '\$${_fmt(coin.lowPrice)}',
                color: AppTheme.priceDown,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: '24h Change',
                value: coin.formattedChange,
                color: coin.isPositive ? AppTheme.priceUp : AppTheme.priceDown,
                icon: coin.isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: '24h Volume',
                value: _fmtVolume(coin.volume),
                color: AppTheme.accentBlue,
                icon: Icons.bar_chart_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000) return v.toStringAsFixed(2);
    if (v >= 1) return v.toStringAsFixed(4);
    return v.toStringAsFixed(6);
  }

  String _fmtVolume(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(2)}K';
    return v.toStringAsFixed(2);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 10)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Alerts Section ───────────────────────────────────────────────────────────

class _AlertsSection extends StatelessWidget {
  final String symbol;
  final CryptoProvider provider;

  const _AlertsSection({required this.symbol, required this.provider});

  @override
  Widget build(BuildContext context) {
    final alerts = provider.getAlertsForCoin(symbol);
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Alerts',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        ...alerts.map((a) => _MiniAlertCard(
              alert: a,
              onDelete: () => provider.deleteAlert(a.id),
            )),
      ],
    );
  }
}

class _MiniAlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onDelete;

  const _MiniAlertCard({required this.alert, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isAbove = alert.condition == AlertCondition.above;
    final color = isAbove ? AppTheme.priceUp : AppTheme.priceDown;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isAbove ? '≥' : '≤',
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '\$${alert.targetPrice}',
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.bgCardAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded,
                  color: AppTheme.textMuted, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Set Alert FAB ────────────────────────────────────────────────────────────

class _SetAlertFab extends StatelessWidget {
  final CoinModel coin;
  final void Function(AlertModel) onAlertCreated;

  const _SetAlertFab({required this.coin, required this.onAlertCreated});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final alert = await showModalBottomSheet<AlertModel?>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => SetAlertBottomSheet(coin: coin),
        );
        if (alert != null) onAlertCreated(alert);
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: AppTheme.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentTeal.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_alert_rounded, color: Colors.black, size: 18),
            SizedBox(width: 8),
            Text(
              'Set Alert',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
