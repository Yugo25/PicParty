import 'package:flutter/material.dart';

/// Monochrome theme: white / near-black surfaces, neutral greys, and no accent
/// colour so the posted photos carry the colour.
class AppTheme {
  AppTheme._();

  static const _lightBg = Color(0xFFFFFFFF);
  static const _darkBg = Color(0xFF0A0A0A);

  static ThemeData light() => _build(
        brightness: Brightness.light,
        background: _lightBg,
        foreground: const Color(0xFF111111),
        secondary: const Color(0xFF6B6B6B),
        divider: const Color(0xFFE6E6E6),
        surfaceHigh: const Color(0xFFF2F2F2),
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        background: _darkBg,
        foreground: const Color(0xFFF5F5F5),
        secondary: const Color(0xFF9A9A9A),
        divider: const Color(0xFF262626),
        surfaceHigh: const Color(0xFF1A1A1A),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color foreground,
    required Color secondary,
    required Color divider,
    required Color surfaceHigh,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: foreground,
      onPrimary: background,
      secondary: secondary,
      onSecondary: background,
      error: const Color(0xFFD93025),
      onError: Colors.white,
      surface: background,
      onSurface: foreground,
      onSurfaceVariant: secondary,
      surfaceContainerLowest: background,
      surfaceContainerLow: background,
      surfaceContainer: surfaceHigh,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: surfaceHigh,
      outline: secondary,
      outlineVariant: divider,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: divider,
      dividerTheme: DividerThemeData(color: divider, thickness: 0.5, space: 0.5),
      splashFactory: NoSplash.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: foreground,
        contentTextStyle: TextStyle(color: background),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      iconTheme: IconThemeData(color: foreground),
      textTheme: base.textTheme.apply(bodyColor: foreground, displayColor: foreground),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      ),
    );
  }
}
