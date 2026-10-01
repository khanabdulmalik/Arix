import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ARIX "Stealth" Design System
/// ─────────────────────────────
/// Deep charcoal backgrounds, cyan/teal neon accents, frosted-glass
/// surfaces, and subtle glow effects.
class ArixTheme {
  ArixTheme._();

  // ─── Core palette ───
  static const Color backgroundDark   = Color(0xFF0A0E14);
  static const Color surfaceDark      = Color(0xFF111820);
  static const Color surfaceLight     = Color(0xFF1A2230);
  static const Color cardDark         = Color(0xFF141C28);
  static const Color divider          = Color(0xFF1E2A3A);

  static const Color accentCyan       = Color(0xFF00F0FF);
  static const Color accentTeal       = Color(0xFF00D4AA);
  static const Color accentBlue       = Color(0xFF3D8BFF);
  static const Color accentViolet     = Color(0xFF8B5CF6);

  static const Color textPrimary      = Color(0xFFE8ECF1);
  static const Color textSecondary    = Color(0xFF7A8BA5);
  static const Color textMuted        = Color(0xFF4A5568);

  static const Color statusEncrypting = Color(0xFFFFC107); // amber
  static const Color statusRelaying   = Color(0xFFFF6B35); // orange
  static const Color statusDelivered  = Color(0xFF00E676); // green
  static const Color statusFailed     = Color(0xFFFF5252); // red

  static const Color bubbleOutgoing   = Color(0xFF0D3B66);
  static const Color bubbleIncoming   = Color(0xFF1A2230);

  // ─── Gradients ───
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentCyan, accentTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0A0E14), Color(0xFF111820)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Shadows / Glows ───
  static List<BoxShadow> neonGlow(Color color, {double blur = 12}) => [
        BoxShadow(color: color.withOpacity(0.35), blurRadius: blur),
        BoxShadow(color: color.withOpacity(0.15), blurRadius: blur * 2),
      ];

  // ─── Border radius ───
  static final BorderRadius cardRadius = BorderRadius.circular(16);
  static final BorderRadius bubbleRadius = BorderRadius.circular(20);
  static final BorderRadius chipRadius = BorderRadius.circular(24);

  // ─── ThemeData ───
  static ThemeData get darkTheme {
    final baseText = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: ColorScheme.dark(
        surface: surfaceDark,
        primary: accentCyan,
        secondary: accentTeal,
        tertiary: accentViolet,
        error: statusFailed,
        onPrimary: backgroundDark,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 1.2,
        ),
        iconTheme: const IconThemeData(color: accentCyan),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
      ),
      textTheme: baseText.copyWith(
        headlineLarge: baseText.headlineLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: baseText.bodyMedium?.copyWith(color: textPrimary),
        bodySmall: baseText.bodySmall?.copyWith(color: textSecondary),
        labelSmall: baseText.labelSmall?.copyWith(
          color: textMuted,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 0.5),
      iconTheme: const IconThemeData(color: accentCyan, size: 22),
    );
  }
}
