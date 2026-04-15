import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF080D1A);
  static const Color surface = Color(0xFF0F1729);
  static const Color cardBg = Color(0xFF161F35);
  static const Color cardBgLight = Color(0xFF1E2A44);
  static const Color divider = Color(0xFF252F49);

  // Brand
  static const Color primary = Color(0xFF4F6EF7);
  static const Color primaryLight = Color(0xFF7A93FF);
  static const Color primaryDark = Color(0xFF3451D1);
  static const Color primarySurface = Color(0xFF1A2353);

  // Semantic
  static const Color positive = Color(0xFF10B981);
  static const Color positiveLight = Color(0xFF34D399);
  static const Color positiveSurface = Color(0xFF0D2E22);
  static const Color negative = Color(0xFFEF4444);
  static const Color negativeLight = Color(0xFFF87171);
  static const Color negativeSurface = Color(0xFF2E0D0D);
  static const Color neutral = Color(0xFF6B7280);

  // Text
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF4B5563);

  // Asset type colors
  static const Color assetBank = Color(0xFF4F6EF7);
  static const Color assetBroker = Color(0xFFA855F7);
  static const Color assetCrypto = Color(0xFFF59E0B);
  static const Color assetMetal = Color(0xFFD4AF37);
  static const Color assetCash = Color(0xFF10B981);
  static const Color assetOther = Color(0xFF64748B);

  // Gradient stops
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F6EF7), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF161F35), Color(0xFF0F1729)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF080D1A), Color(0xFF0A1128)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
