import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/crypto_provider.dart';
import 'screens/home_screen.dart';
import 'screens/alerts_screen.dart';
import 'theme/app_theme.dart';

class CryptoTrackerApp extends StatelessWidget {
  const CryptoTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CryptoProvider()..init(),
      child: MaterialApp(
        title: 'Crypto Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _MainShell(),
      ),
    );
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late AnimationController _slideCtrl;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _onTap(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      extendBody: true,
      body: IndexedStack(index: _index, children: const [
        HomeScreen(),
        AlertsScreen(),
      ]),
      bottomNavigationBar: _GlassBottomNav(
        selectedIndex: _index,
        onTap: _onTap,
      ),
    );
  }
}

class _GlassBottomNav extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const _GlassBottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            color: AppTheme.bgCard.withValues(alpha:0.85),
            border: const Border(
              top: BorderSide(color: AppTheme.borderSubtle, width: 0.8),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                _NavItem(
                  index: 0,
                  selectedIndex: selectedIndex,
                  icon: Icons.show_chart_rounded,
                  label: 'Markets',
                  onTap: onTap,
                ),
                _NavItem(
                  index: 1,
                  selectedIndex: selectedIndex,
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications_rounded,
                  label: 'Alerts',
                  onTap: onTap,
                  badge: Consumer<CryptoProvider>(
                    builder: (_, p, __) {
                      final c = p.activeAlertsCount;
                      return c > 0 ? Text(c.toString()) : const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final void Function(int) onTap;
  final Widget? badge;

  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == selectedIndex;
    final color = selected ? AppTheme.accentTeal : AppTheme.textMuted;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indicator line
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              height: 2,
              width: selected ? 28 : 0,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: selected ? AppTheme.primaryGradient : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppTheme.accentTeal.withValues(alpha:0.7),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    selected ? (activeIcon ?? icon) : icon,
                    key: ValueKey(selected),
                    color: color,
                    size: 22,
                  ),
                ),
                if (badge != null)
                  Builder(
                    builder: (ctx) {
                      if (badge is Text) return const SizedBox.shrink();
                      return badge!;
                    },
                  ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: 0.3,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
