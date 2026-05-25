import 'package:flutter/material.dart';

class AppColors {
  // ── Core Palette ──────────────────────────────────────────────────────────────
  static const Color background     = Color(0xFF16082A); // Deep dark purple (screen bg)
  static const Color surface        = Color(0xFF1E0B38); // Card / bottom nav background
  static const Color cardColor      = Color(0xFF251060); // Elevated card / mid gradient
  static const Color surfaceVariant = Color(0xFF3D1A6E); // Lighter purple card hover
  static const Color shimmerHigh    = Color(0xFF4A2A7A); // Shimmer highlight
  static const Color playerBg       = Color(0xFF0D0630); // Darkest navy for player screen
  static const Color dividerColor   = Color(0xFF4A2A7A); // Subtle purple divider

  // ── Brand / Primary ───────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF8B2FC9); // Vibrant purple (active buttons, pills)
  static const Color primaryDark    = Color(0xFF7C3AED); // Deeper violet (pressed states / glow)
  static const Color primaryLight   = Color(0xFF9B59F5); // Electric violet (active tab glow)

  // ── Secondary / Accent ────────────────────────────────────────────────────────
  static const Color secondary      = Color(0xFF6B4FA0); // Frosted purple (icon buttons)
  static const Color accent         = Color(0xFFE040FB); // Hot pink / neon magenta (highlights)
  static const Color accentGold     = Color(0xFFD4880A); // Amber gold (Gold Record badge)

  // ── Text ──────────────────────────────────────────────────────────────────────
  static const Color textPrimary    = Colors.white;                // Headings
  static const Color textSecondary  = Color(0xFFB8A0D4); // Muted lavender-white (subtitles)
  static const Color textDisabled   = Color(0xFF9080B0); // Pale purple-gray (timestamps, meta)

  // ── Semantic ──────────────────────────────────────────────────────────────────
  static const Color error          = Color(0xFFE040FB); // Reuse magenta for errors (vivid)
  static const Color iconInactive   = Color(0xFFA98EC9); // Soft lavender (inactive nav icons)

  // ── Glassmorphism Overlays ────────────────────────────────────────────────────
  static const Color glassCard      = Color(0x991E0A3C); // Dark purple @ 60% opacity
  static const Color glassPill      = Color(0x593C1EA0); // Purple chip @ 35% opacity

  // ── Gradients ─────────────────────────────────────────────────────────────────
  static const List<Color> backgroundGradient = [
    Color(0xFF3D1A6E), // Top — Purple Violet
    Color(0xFF251060), // Mid — Deep Indigo
    Color(0xFF0D0630), // Bottom — Navy Black
  ];

  static const List<Color> accentGradient = [
    Color(0xFF9B59F5), // Electric violet
    Color(0xFFE040FB), // Hot pink / magenta
  ];

  static const List<Color> authGradient = backgroundGradient;

  // ── Outer / Page Background (scaffold around phone) ───────────────────────────
  static const Color pageBackground = Color(0xFFC9B8E8); // Soft lavender (outside cards)
}
