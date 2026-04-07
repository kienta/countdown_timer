import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0F0F1A);
  static const surface = Color(0xFF1A1A2E);
  static const surf2 = Color(0xFF16213E);
  static const border = Color(0x0DFFFFFF);
  static const accent = Color(0xFF7C3AED);
  static const accentLight = Color(0xFFA855F7);
  static const glow = Color(0x359D5CF6);
  static const success = Color(0xFF10B981);
  static const warn = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const text = Color(0xFFE2E8F0);
  static const muted = Color(0xFF64748B);
  static const accentText = Color(0xFFA78BFA);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentLight,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      fontFamily: 'SegoeUI',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.text, fontSize: 14),
        bodyMedium: TextStyle(color: AppColors.text, fontSize: 13),
        bodySmall: TextStyle(color: AppColors.muted, fontSize: 12),
        titleLarge: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w700),
        labelSmall: TextStyle(
          color: AppColors.muted,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.muted,
          side: const BorderSide(color: Color(0x14FFFFFF)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0x10FFFFFF), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0x10FFFFFF), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: const TextStyle(color: AppColors.muted),
        labelStyle: const TextStyle(color: AppColors.muted),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

/// Status badge decoration
BoxDecoration statusBadgeDecoration(String status) {
  Color bg;
  switch (status) {
    case 'running':
      bg = const Color(0x257C3AED);
      break;
    case 'paused':
      bg = const Color(0x1AF59E0B);
      break;
    case 'done':
      bg = const Color(0x1A10B981);
      break;
    default:
      bg = const Color(0x0AFFFFFF);
  }
  return BoxDecoration(
    color: bg,
    borderRadius: BorderRadius.circular(99),
  );
}

Color statusBadgeTextColor(String status) {
  switch (status) {
    case 'running':
      return AppColors.accentText;
    case 'paused':
      return AppColors.warn;
    case 'done':
      return AppColors.success;
    default:
      return AppColors.muted;
  }
}

/// Accent gradient for buttons
const accentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.accent, AppColors.accentLight],
);

/// Progress bar gradient
const progressGradient = LinearGradient(
  colors: [AppColors.accent, AppColors.accentLight],
);

const progressLowGradient = LinearGradient(
  colors: [AppColors.warn, Color(0xFFF97316)],
);

const progressDoneGradient = LinearGradient(
  colors: [AppColors.success, Color(0xFF34D399)],
);
