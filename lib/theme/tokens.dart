import 'package:flutter/widgets.dart';

/// Spacing, radii and sizes shared by every screen, so Home, Explore, Create,
/// Inbox and Profile line up.
class Tokens {
  Tokens._();

  /// Side margin of page content.
  static const gutter = 16.0;

  /// Gap between grid cards.
  static const gridGap = 12.0;

  /// Small rounding for photos, inputs and buttons.
  static const radius = 8.0;
  static const radiusSmall = 6.0;
  static const radiusPill = 999.0;

  /// Height of primary buttons, inputs and the bottom action bar.
  static const controlHeight = 48.0;

  /// Height of filter pills.
  static const pillHeight = 36.0;

  /// Widest a page's content gets on tablets and desktop browsers.
  static const maxContentWidth = 600.0;

  /// Large page titles ("Explore", "Inbox").
  static const pageTitleSize = 30.0;

  static const pagePadding = EdgeInsets.symmetric(horizontal: gutter);
}
