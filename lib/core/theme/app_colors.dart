import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.muted,
    required this.tint,
    required this.line,
    required this.badge,
    required this.badgeInk,
    required this.header,
    required this.headerInk,
  });

  final Color muted;
  final Color tint;
  final Color line;
  final Color badge;
  final Color badgeInk;
  final Color header;
  final Color headerInk;

  // Sheetal Brand Colors from Prototype
  static const primary = Color(0xFFDA3A7B); // Sheetal Magenta
  static const primaryDark = Color(0xFFD43375);
  static const primaryLight = Color(0xFFE0508A);
  static const deepInk = Color(0xFF2D1A4F); // Deep Plum
  static const royalPurple = Color(0xFF583090); // Brand Purple Accent
  static const softMuted = Color(0xFF6B5F85);
  static const borderPink = Color(0xFFF2B6DC);
  static const linePink = Color(0xFFF3CEE6);
  static const pagePink = Color(0xFFF3CEE6);
  static const warmCard = Color(0xFFFFF4E8);
  static const accent = Color(0xFF7FB942); // Fresh green
  static const hotPink = Color(0xFFEC5BB0);

  // Backward compatibility
  static const softPink = Color(0xFFF58CCB);
  static const primaryPink = Color(0xFFEC5BB0);
  static const freshGreen = Color(0xFF7FB942);
  static const frost = Color(0xFFFDF4F9);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD43375), Color(0xFFE0508A)],
  );

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEC5BB0), Color(0xFFD93E97)],
  );

  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.6, 1.0],
    colors: [Color(0xFFFFFFFF), Color(0xFFFFF4F9), Color(0xFFFBEFF6)],
  );

  static const imgCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF4E8), Color(0xFFFFE3C8)],
  );

  static const ringGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF3CEE6), Color(0xFFC9B6EA)],
  );

  static const light = AppColors(
    muted: Color(0xFF6B5F85),
    tint: Color(0x1FDA3A7B),
    line: Color(0xFFF3CEE6),
    badge: Color(0xFF583090),
    badgeInk: Colors.white,
    header: Color(0xFFDA3A7B),
    headerInk: Colors.white,
  );

  static const dark = AppColors(
    muted: Color(0xFFB5A9C7),
    tint: Color(0x33DA3A7B),
    line: Color(0x3DFFFFFF),
    badge: Color(0xFF583090),
    badgeInk: Colors.white,
    header: Color(0xFFDA3A7B),
    headerInk: Colors.white,
  );

  @override
  AppColors copyWith({
    Color? muted,
    Color? tint,
    Color? line,
    Color? badge,
    Color? badgeInk,
    Color? header,
    Color? headerInk,
  }) {
    return AppColors(
      muted: muted ?? this.muted,
      tint: tint ?? this.tint,
      line: line ?? this.line,
      badge: badge ?? this.badge,
      badgeInk: badgeInk ?? this.badgeInk,
      header: header ?? this.header,
      headerInk: headerInk ?? this.headerInk,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      muted: Color.lerp(muted, other.muted, t)!,
      tint: Color.lerp(tint, other.tint, t)!,
      line: Color.lerp(line, other.line, t)!,
      badge: Color.lerp(badge, other.badge, t)!,
      badgeInk: Color.lerp(badgeInk, other.badgeInk, t)!,
      header: Color.lerp(header, other.header, t)!,
      headerInk: Color.lerp(headerInk, other.headerInk, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
