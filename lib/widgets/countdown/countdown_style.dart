import 'package:flutter/material.dart';

/// The look of a photo-backed countdown, separate from its data
/// ([CountdownSnapshot]). New styles (fonts, placement, sizes) can be added as
/// more instances without touching the countdown logic.
class CountdownStyle {
  /// Where the timer block sits inside the photo (x, y in -1..1).
  final Alignment alignment;
  final TextStyle labelStyle;
  final TextStyle digitsStyle;
  final TextStyle closedStyle;
  final TextStyle targetStyle;
  final double labelGap;
  final double targetGap;

  const CountdownStyle({
    required this.alignment,
    required this.labelStyle,
    required this.digitsStyle,
    required this.closedStyle,
    required this.targetStyle,
    this.labelGap = 2,
    this.targetGap = 4,
  });

  static const _shadow = [Shadow(color: Color(0x66000000), blurRadius: 8)];
  static const _tabular = [FontFeature.tabularFigures()];

  /// Default in-feed style: white text a little below the centre of the photo.
  static const overlay = CountdownStyle(
    alignment: Alignment(0, 0.66),
    labelStyle: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, shadows: _shadow),
    digitsStyle: TextStyle(
        color: Colors.white, fontSize: 52, height: 1.1, fontWeight: FontWeight.w700, letterSpacing: 0.5, fontFeatures: _tabular, shadows: _shadow),
    closedStyle: TextStyle(color: Colors.white, fontSize: 34, height: 1.25, fontWeight: FontWeight.w700, shadows: _shadow),
    targetStyle: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, fontFeatures: _tabular, shadows: _shadow),
  );

  /// Smaller variant for compact surfaces such as the Party page header.
  static const compact = CountdownStyle(
    alignment: Alignment(0, 0.55),
    labelStyle: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, shadows: _shadow),
    digitsStyle: TextStyle(
        color: Colors.white, fontSize: 40, height: 1.1, fontWeight: FontWeight.w700, letterSpacing: 0.5, fontFeatures: _tabular, shadows: _shadow),
    closedStyle: TextStyle(color: Colors.white, fontSize: 28, height: 1.25, fontWeight: FontWeight.w700, shadows: _shadow),
    targetStyle: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, fontFeatures: _tabular, shadows: _shadow),
  );
}
