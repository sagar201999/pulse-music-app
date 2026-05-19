import 'package:flutter/material.dart';

class AppColors {
  // ── Core Palette ──────────────────────────────────────────────────────────────
  static const Color background    = Color(0xFF121212); // App background
  static const Color surface       = Color(0xFF121212); // Card background
  static const Color cardColor     = Color(0xFF282828); // Elevated card / shimmer base
  static const Color surfaceVariant = Color(0xFF3E3E3E); // For lighter card hover
  static const Color shimmerHigh   = Color(0xFF3E3E3E); // Shimmer highlight
  static const Color playerBg      = Color(0xFF000000); // Pure black for player screen
  static const Color dividerColor  = Color(0xFF3E3E3E); // Subtle divider

  // ── Brand ─────────────────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF1DB954); // Spotify green
  static const Color primaryDark   = Color(0xFF158A3E); // Darker green (pressed states)

  // ── Text ──────────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Colors.white;
  static const Color textSecondary = Color(0xFFB3B3B3); // Muted text
  static const Color textDisabled  = Color(0xFF535353); // Disabled / placeholder

  // ── Semantic ──────────────────────────────────────────────────────────────────
  static const Color secondary     = Color(0xFF535353); // Muted gray (icons, borders)
  static const Color error         = Colors.red;

  // ── Auth gradient (Get Started + Login screens) ───────────────────────────────
  static const List<Color> authGradient = [
    Color(0xFF1DB954), // Green at top
    Color(0xFF0D5C2B), // Mid dark green
    Color(0xFF000000), // Pure black at bottom
  ];
}
