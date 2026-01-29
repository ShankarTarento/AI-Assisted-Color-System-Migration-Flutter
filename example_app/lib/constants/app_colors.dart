import 'package:flutter/material.dart';

/// Large color constants class with 200+ colors
/// This represents the "before" state for migration testing
class AppColors {
  // ============================================================
  // PRIMARY COLORS (Core - map to ColorScheme.primary)
  // ============================================================
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF90CAF9);
  
  // ============================================================
  // SECONDARY/ACCENT COLORS (Core - map to ColorScheme.secondary)
  // ============================================================
  static const Color accentGreen = Color(0xFF388E3C);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentPurple = Color(0xFF9C27B0);
  
  // ============================================================
  // STATUS COLORS (Core - map to ColorScheme properties)
  // ============================================================
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color warningYellow = Color(0xFFFBC02D);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color infoBlue = Color(0xFF0288D1);
  
  // ============================================================
  // BLUE VARIANTS (ThemeExtension candidates)
  // ============================================================
  static const Color blue50 = Color(0xFFE3F2FD);
  static const Color blue100 = Color(0xFFBBDEFB);
  static const Color blue200 = Color(0xFF90CAF9);
  static const Color blue300 = Color(0xFF64B5F6);
  static const Color blue400 = Color(0xFF42A5F5);
  static const Color blue500 = Color(0xFF2196F3);
  static const Color blue600 = Color(0xFF1E88E5);
  static const Color blue700 = Color(0xFF1976D2);
  static const Color blue800 = Color(0xFF1565C0);
  static const Color blue900 = Color(0xFF0D47A1);
  
  // ============================================================
  // GREEN VARIANTS (ThemeExtension candidates)
  // ============================================================
  static const Color green50 = Color(0xFFE8F5E9);
  static const Color green100 = Color(0xFFC8E6C9);
  static const Color green200 = Color(0xFFA5D6A7);
  static const Color green300 = Color(0xFF81C784);
  static const Color green400 = Color(0xFF66BB6A);
  static const Color green500 = Color(0xFF4CAF50);
  static const Color green600 = Color(0xFF43A047);
  static const Color green700 = Color(0xFF388E3C);
  static const Color green800 = Color(0xFF2E7D32);
  static const Color green900 = Color(0xFF1B5E20);
  
  // ============================================================
  // RED VARIANTS (ThemeExtension candidates)
  // ============================================================
  static const Color red50 = Color(0xFFFFEBEE);
  static const Color red100 = Color(0xFFFFCDD2);
  static const Color red200 = Color(0xFFEF9A9A);
  static const Color red300 = Color(0xFFE57373);
  static const Color red400 = Color(0xFFEF5350);
  static const Color red500 = Color(0xFFF44336);
  static const Color red600 = Color(0xFFE53935);
  static const Color red700 = Color(0xFFD32F2F);
  static const Color red800 = Color(0xFFC62828);
  static const Color red900 = Color(0xFFB71C1C);
  
  // ============================================================
  // ORANGE VARIANTS (ThemeExtension candidates)
  // ============================================================
  static const Color orange50 = Color(0xFFFFF3E0);
  static const Color orange100 = Color(0xFFFFE0B2);
  static const Color orange200 = Color(0xFFFFCC80);
  static const Color orange300 = Color(0xFFFFB74D);
  static const Color orange400 = Color(0xFFFFA726);
  static const Color orange500 = Color(0xFFFF9800);
  static const Color orange600 = Color(0xFFFB8C00);
  static const Color orange700 = Color(0xFFF57C00);
  static const Color orange800 = Color(0xFFEF6C00);
  static const Color orange900 = Color(0xFFE65100);
  
  // ============================================================
  // PURPLE VARIANTS (ThemeExtension candidates)
  // ============================================================
  static const Color purple50 = Color(0xFFF3E5F5);
  static const Color purple100 = Color(0xFFE1BEE7);
  static const Color purple200 = Color(0xFFCE93D8);
  static const Color purple300 = Color(0xFFBA68C8);
  static const Color purple400 = Color(0xFFAB47BC);
  static const Color purple500 = Color(0xFF9C27B0);
  static const Color purple600 = Color(0xFF8E24AA);
  static const Color purple700 = Color(0xFF7B1FA2);
  static const Color purple800 = Color(0xFF6A1B9A);
  static const Color purple900 = Color(0xFF4A148C);
  
  // ============================================================
  // YELLOW VARIANTS (ThemeExtension candidates)
  // ============================================================
  static const Color yellow50 = Color(0xFFFFFDE7);
  static const Color yellow100 = Color(0xFFFFF9C4);
  static const Color yellow200 = Color(0xFFFFF59D);
  static const Color yellow300 = Color(0xFFFFF176);
  static const Color yellow400 = Color(0xFFFFEE58);
  static const Color yellow500 = Color(0xFFFFEB3B);
  static const Color yellow600 = Color(0xFFFDD835);
  static const Color yellow700 = Color(0xFFFBC02D);
  static const Color yellow800 = Color(0xFFF9A825);
  static const Color yellow900 = Color(0xFFF57F17);
  
  // ============================================================
  // GREY SCALE (Core - map to ColorScheme surface/background)
  // ============================================================
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  
  // ============================================================
  // BACKGROUND COLORS (Core - map to ColorScheme)
  // ============================================================
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // ============================================================
  // TEXT COLORS (Core - map to ColorScheme.onBackground, etc.)
  // ============================================================
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  
  // ============================================================
  // COMPONENT-SPECIFIC COLORS (ThemeExtension candidates)
  // ============================================================
  static const Color buttonPrimary = Color(0xFF1976D2);
  static const Color buttonSecondary = Color(0xFF388E3C);
  static const Color buttonDisabled = Color(0xFFBDBDBD);
  
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color cardShadow = Color(0x1F000000);
  
  static const Color inputBackground = Color(0xFFF5F5F5);
  static const Color inputBorder = Color(0xFFBDBDBD);
  static const Color inputFocusBorder = Color(0xFF1976D2);
  static const Color inputErrorBorder = Color(0xFFD32F2F);
  
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1F000000);
  static const Color overlay = Color(0x66000000);
  
  // ============================================================
  // LEGACY COLORS (Keep unchanged - low usage)
  // ============================================================
  static const Color legacyPurple = Color(0xFF9C27B0);
  static const Color oldButtonColor = Color(0xFF607D8B);
  static const Color deprecatedPink = Color(0xFFE91E63);
  static const Color oldAccentCyan = Color(0xFF00BCD4);
  static const Color legacyLime = Color(0xFFCDDC39);
  
  // ============================================================
  // BRAND COLORS (ThemeExtension candidates)
  // ============================================================
  static const Color brandPrimary = Color(0xFF1976D2);
  static const Color brandSecondary = Color(0xFF388E3C);
  static const Color brandTertiary = Color(0xFFFF9800);
  
  // ============================================================
  // SEMANTIC COLORS (Core - map to ColorScheme)
  // ============================================================
  static const Color linkBlue = Color(0xFF1976D2);
  static const Color linkVisited = Color(0xFF7B1FA2);
  
  // ============================================================
  // CHART COLORS (ThemeExtension candidates)
  // ============================================================
  static const Color chartColor1 = Color(0xFF2196F3);
  static const Color chartColor2 = Color(0xFF4CAF50);
  static const Color chartColor3 = Color(0xFFFF9800);
  static const Color chartColor4 = Color(0xFF9C27B0);
  static const Color chartColor5 = Color(0xFFF44336);
  static const Color chartColor6 = Color(0xFF00BCD4);
  static const Color chartColor7 = Color(0xFFFFEB3B);
  static const Color chartColor8 = Color(0xFFE91E63);
  
  // ============================================================
  // UNUSED COLORS (Should be flagged for removal)
  // ============================================================
  static const Color unused1 = Color(0xFF795548);
  static const Color unused2 = Color(0xFF9E9D24);
  static const Color unused3 = Color(0xFF5D4037);
  static const Color unused4 = Color(0xFF455A64);
  static const Color unused5 = Color(0xFF6D4C41);
  
  // Prevent instantiation
  AppColors._();
}
