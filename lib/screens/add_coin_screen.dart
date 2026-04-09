import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/coin_model.dart';
import '../providers/crypto_provider.dart';
import '../services/binance_service.dart';
import '../theme/app_theme.dart';

class AddCoinScreen extends StatefulWidget {
  const AddCoinScreen({super.key});

  @override
  State<AddCoinScreen> createState() => _AddCoinScreenState();
}

class _AddCoinScreenState extends State<AddCoinScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, String>> _allPairs = [];
  List<Map<String, String>> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPairs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPairs() async {
    final all = await BinanceService.fetchAllUsdtPairs();
    if (mounted) {
      setState(() {
        _allPairs = all.isNotEmpty ? all : kDefaultCoins;
        _filtered = _allPairs;
        _loading = false;
      });
    }
  }

  void _onSearch(String q) {
    final upper = q.toUpperCase();
    setState(() {
      _filtered = upper.isEmpty
          ? _allPairs
          : _allPairs
              .where((c) =>
                  c['symbol']!.contains(upper) ||
                  c['base']!.contains(upper))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CryptoProvider>();
    final watched = provider.coins.map((c) => c.symbol).toSet();

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
                  ShaderMask(
                    shaderCallback: (b) =>
                        AppTheme.primaryGradient.createShader(b),
                    child: const Icon(Icons.add_circle_outline_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text('Add Coins'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 76),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _onSearch,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search symbol or name...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 10),
                  child: Icon(Icons.search_rounded,
                      color: AppTheme.textMuted, size: 20),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          _onSearch('');
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.close_rounded,
                              color: AppTheme.textMuted, size: 16),
                        ),
                      )
                    : null,
              ),
            ),
          ),

          // Result count
          if (!_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
              child: Row(
                children: [
                  Text(
                    '${_filtered.length} pairs available',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                                AppTheme.accentTeal.withValues(alpha:0.8)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text('Loading pairs...',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 13)),
                      ],
                    ),
                  )
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                color: AppTheme.textMuted.withValues(alpha:0.4),
                                size: 48),
                            const SizedBox(height: 12),
                            const Text('No results',
                                style: TextStyle(
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) {
                          final coin = _filtered[i];
                          final sym = coin['symbol']!;
                          final base = coin['base']!;
                          final isWatched = watched.contains(sym);
                          final coinColor = AppTheme.coinColor(sym);

                          return _CoinRow(
                            base: base,
                            symbol: sym,
                            coinColor: coinColor,
                            isWatched: isWatched,
                            onAdd: () async {
                              await provider.addCoin(coin);
                              watched.add(sym);
                              if (ctx.mounted) {
                                setState(() {});
                                _showAdded(ctx, base);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showAdded(BuildContext context, String base) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppTheme.accentTeal, size: 16),
          const SizedBox(width: 8),
          Text('$base added to watchlist',
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 13)),
        ],
      ),
      backgroundColor: AppTheme.bgCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }
}

class _CoinRow extends StatelessWidget {
  final String base;
  final String symbol;
  final Color coinColor;
  final bool isWatched;
  final VoidCallback onAdd;

  const _CoinRow({
    required this.base,
    required this.symbol,
    required this.coinColor,
    required this.isWatched,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final label = base.length >= 2 ? base.substring(0, 2) : base;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  coinColor.withValues(alpha:0.2),
                  coinColor.withValues(alpha:0.05),
                ],
              ),
              border:
                  Border.all(color: coinColor.withValues(alpha:0.35), width: 1),
              boxShadow: [
                BoxShadow(
                    color: coinColor.withValues(alpha:0.15), blurRadius: 8)
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                    color: coinColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(base,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text(
                  symbol,
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),

          // Action button
          isWatched
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentTeal.withValues(alpha:0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.accentTeal.withValues(alpha:0.25),
                        width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded,
                          color: AppTheme.accentTeal, size: 12),
                      const SizedBox(width: 4),
                      const Text('Added',
                          style: TextStyle(
                              color: AppTheme.accentTeal,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentTeal.withValues(alpha:0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
