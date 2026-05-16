import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors from screenshots
  static const bg = Color(0xFFF3F3F4);
  static const white = Color(0xFFFFFFFF);
  static const sidebarBg = Color(0xFFFFFFFF);
  static const topBarBorder = Color(0xFFE0E0E0);
  static const activeBlue = Color(0xFF1A73E8);
  static const activeBlueLight = Color(0xFFE8F0FE);
  static const textPrimary = Color(0xFF1A1C1C);
  static const textSecondary = Color(0xFF5F6368);
  static const textHint = Color(0xFF9AA0A6);
  static const border = Color(0xFFDDE1E6);
  static const chipBg = Color(0xFFFFFFFF);
  static const badgeBlueBg = Color(0xFFE8F0FE);
  static const badgeBlueText = Color(0xFF1A73E8);
  static const btnBlack = Color(0xFF1C1C1C);
  static const imagePlaceholder = Color(0xFFE8E8E8);

  static TextStyle outfit(double size, FontWeight weight, Color color,
      {double? letterSpacing}) {
    return GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing);
  }

  static TextStyle inter(double size, FontWeight weight, Color color) {
    return GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);
  }
}
