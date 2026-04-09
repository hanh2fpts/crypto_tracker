import 'package:flutter/material.dart';

class AppTheme {
  // ─── Background ────────────────────────────────────────────────────────────
  static const Color bgDeep    = Color(0xFF060B14);
  static const Color bgPrimary = Color(0xFF080D18);
  static const Color bgCard    = Color(0xFF0C1425);
  static const Color bgCardAlt = Color(0xFF0F1A2E);
  static const Color bgInput   = Color(0xFF111D30);

  // ─── Borders ───────────────────────────────────────────────────────────────
  static const Color borderSubtle = Color(0x14FFFFFF);   // 8% white
  static const Color borderMid    = Color(0x1FFFFFFF);   // 12% white
  static const Color borderStrong = Color(0x33FFFFFF);   // 20% white

  // ─── Accents ───────────────────────────────────────────────────────────────
  static const Color accentTeal   = Color(0xFF00E5C3);
  static const Color accentBlue   = Color(0xFF4B9EFF);
  static const Color accentPurple = Color(0xFF8B6DFF);

  // ─── Price Colors ──────────────────────────────────────────────────────────
  static const Color priceUp   = Color(0xFF00E676);
  static const Color priceDown = Color(0xFFFF4B6E);

  // ─── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF0F6FF);
  static const Color textSecondary = Color(0xFF7A97C2);
  static const Color textMuted     = Color(0xFF3A5170);

  // ─── Gradient Shortcuts ────────────────────────────────────────────────────
  static const List<Color> accentGradient = [accentTeal, accentBlue];
  static const List<Color> upGradient     = [Color(0xFF00E676), Color(0xFF00B8A9)];
  static const List<Color> downGradient   = [Color(0xFFFF4B6E), Color(0xFFFF8C00)];

  static LinearGradient get primaryGradient => const LinearGradient(
    colors: accentGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Coin Colors ───────────────────────────────────────────────────────────
  static Color coinColor(String symbol) {
    const map = {
      'BTC': Color(0xFFF7931A),
      'ETH': Color(0xFF7B8CFF),
      'BNB': Color(0xFFF3BA2F),
      'SOL': Color(0xFF9945FF),
      'XRP': Color(0xFF4A90D9),
      'ADA': Color(0xFF0D7AD2),
      'DOGE': Color(0xFFD4B13F),
      'AVAX': Color(0xFFE84142),
      'DOT': Color(0xFFE6007A),
      'LINK': Color(0xFF3B82F6),
      'MATIC': Color(0xFF8247E5),
      'LTC': Color(0xFFBCBCBC),
      'UNI': Color(0xFFFF007A),
      'ATOM': Color(0xFF6F7BFF),
      'ETC': Color(0xFF328332),
    };
    final base = symbol.replaceAll('USDT', '');
    return map[base] ?? accentTeal;
  }

  // ─── Theme Data ────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: accentTeal,
      secondary: accentBlue,
      surface: bgCard,
      onPrimary: Colors.black,
      onSurface: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      iconTheme: IconThemeData(color: textSecondary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgCard,
      selectedItemColor: accentTeal,
      unselectedItemColor: textMuted,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: const DividerThemeData(
      color: borderSubtle,
      thickness: 0.5,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgInput,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderSubtle, width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderSubtle, width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentTeal, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textMuted, fontSize: 14),
    ),
  );
}
