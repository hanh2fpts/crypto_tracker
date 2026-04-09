import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crypto_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/coin_tile.dart';
import 'coin_detail_screen.dart';
import 'add_coin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Consumer<CryptoProvider>(
        builder: (ctx, provider, _) => _buildBody(ctx, provider),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AppBar(
            backgroundColor: AppTheme.bgPrimary.withValues(alpha:0.7),
            title: _isSearching
                ? TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search coin name or symbol...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      fillColor: Colors.transparent,
                      filled: false,
                    ),
                    onChanged: (v) =>
                        context.read<CryptoProvider>().setSearchQuery(v),
                  )
                : Row(
                    children: [
                      // Live dot
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.priceUp,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.priceUp.withValues(alpha:
                                    0.3 + 0.5 * _pulseCtrl.value),
                                blurRadius: 6 + 6 * _pulseCtrl.value,
                              ),
                            ],
                          ),
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppTheme.primaryGradient.createShader(bounds),
                        child: const Text(
                          'CryptoTracker',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
            actions: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isSearching ? Icons.close_rounded : Icons.search_rounded,
                    key: ValueKey(_isSearching),
                    color: AppTheme.textSecondary,
                    size: 22,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchCtrl.clear();
                      context.read<CryptoProvider>().setSearchQuery('');
                    }
                  });
                },
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddCoinScreen()),
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 14),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentTeal.withValues(alpha:0.35),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.black, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CryptoProvider provider) {
    if (provider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated gradient ring
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1200),
              builder: (_, t, __) => Transform.rotate(
                angle: t * 2 * 3.14159,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AppTheme.accentTeal,
                        AppTheme.accentBlue,
                        AppTheme.accentTeal.withValues(alpha:0),
                      ],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppTheme.bgPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (b) =>
                  AppTheme.primaryGradient.createShader(b),
              child: const Text(
                'Connecting to Binance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final coins = provider.coins;

    return RefreshIndicator(
      color: AppTheme.accentTeal,
      backgroundColor: AppTheme.bgCard,
      displacement: 100,
      onRefresh: provider.init,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 90)),

          // ── Market Pulse Card ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: _MarketPulseCard(provider: provider),
            ),
          ),

          // ── Section header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
              child: Row(
                children: [
                  const Text(
                    'Markets',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${coins.length}',
                      style: const TextStyle(
                        color: AppTheme.accentTeal,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Coin list ──────────────────────────────────────────────────
          if (coins.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.candlestick_chart_outlined,
                        color: AppTheme.textMuted.withValues(alpha:0.4), size: 60),
                    const SizedBox(height: 16),
                    const Text('No coins found',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 15)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CoinTile(
                      coin: coins[i],
                      onTap: () => Navigator.push(
                        context,
                        _slideRoute(
                          CoinDetailScreen(symbol: coins[i].symbol),
                        ),
                      ),
                      onLongPress: () => _confirmRemove(
                          context, provider, coins[i].symbol,
                          coins[i].baseAsset),
                    ),
                  ),
                  childCount: coins.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context, CryptoProvider provider,
      String symbol, String base) {
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Remove $base?',
        subtitle: 'Also removes all alerts for this coin.',
        confirmLabel: 'Remove',
        confirmColor: AppTheme.priceDown,
        onConfirm: () => provider.removeCoin(symbol),
      ),
    );
  }

  Route _slideRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a1, __) => page,
        transitionsBuilder: (_, a1, __, child) => SlideTransition(
          position: Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a1, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      );
}

// ─── Market Pulse Card ────────────────────────────────────────────────────────

class _MarketPulseCard extends StatelessWidget {
  final CryptoProvider provider;
  const _MarketPulseCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final coins = provider.coins;
    if (coins.isEmpty) return const SizedBox.shrink();

    final gainers = coins.where((c) => c.isPositive).length;
    final losers = coins.length - gainers;
    final pct = coins.isEmpty ? 0.5 : gainers / coins.length;
    final isBullish = pct >= 0.5;

    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isBullish
              ? AppTheme.upGradient
              : AppTheme.downGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isBullish
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: isBullish ? AppTheme.priceUp : AppTheme.priceDown,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Market Sentiment',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  isBullish ? 'BULLISH' : 'BEARISH',
                  style: TextStyle(
                    color: isBullish ? AppTheme.priceUp : AppTheme.priceDown,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Segmented bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: LayoutBuilder(builder: (_, constraints) {
                  return Stack(
                    children: [
                      // Background
                      Container(color: AppTheme.bgCardAlt),
                      // Green portion
                      FractionallySizedBox(
                        widthFactor: pct.clamp(0.02, 0.98),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppTheme.upGradient,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PulseStat(
                  label: 'Gainers',
                  value: '$gainers',
                  color: AppTheme.priceUp,
                  icon: Icons.arrow_upward_rounded,
                ),
                _PulseStat(
                  label: 'Losers',
                  value: '$losers',
                  color: AppTheme.priceDown,
                  icon: Icons.arrow_downward_rounded,
                ),
                _PulseStat(
                  label: 'Alerts',
                  value: '${provider.activeAlertsCount}',
                  color: AppTheme.accentTeal,
                  icon: Icons.notifications_outlined,
                ),
                _PulseStat(
                  label: 'Tracking',
                  value: '${coins.length}',
                  color: AppTheme.textSecondary,
                  icon: Icons.radar_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _PulseStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 3),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}

// ─── Confirm Dialog ───────────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;

  const _ConfirmDialog({
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderMid),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onConfirm();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor.withValues(alpha:0.15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(confirmLabel,
                        style: TextStyle(
                            color: confirmColor,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
