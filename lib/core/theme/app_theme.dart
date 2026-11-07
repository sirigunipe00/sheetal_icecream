import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sheetal_icecream/core/theme/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static const _font = 'DM Sans';

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFEC5BB0),
      onPrimary: Colors.white,
      secondary: Color(0xFF7FB942),
      onSecondary: Colors.white,
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF2E1025),
    );
    return _build(
      scheme: scheme,
      scaffold: const Color(0xFFFFF7FB),
      colors: AppColors.light,
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFEC5BB0),
      onPrimary: Colors.white,
      secondary: Color(0xFF7FB942),
      onSecondary: Colors.white,
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: Color(0xFF26101E),
      onSurface: Color(0xFFFCE7F3),
    );
    return _build(
      scheme: scheme,
      scaffold: const Color(0xFF190B14),
      colors: AppColors.dark,
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Color scaffold,
    required AppColors colors,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: _font,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: overlay,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: _font,
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: _font),
      dividerColor: colors.line,
      extensions: [colors],
    );
  }
}
