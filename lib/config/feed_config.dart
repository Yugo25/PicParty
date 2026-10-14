/// Tunable values for the home feed. Kept in one place so they are easy to adjust.
class FeedConfig {
  FeedConfig._();

  /// How long a photo stays on screen while auto-advance is on.
  static const photoAutoAdvanceInterval = Duration(seconds: 5);

  /// Width / height of the photo-backed countdown area. Fixed so switching
  /// posts never changes the Party's height.
  static const mediaAspectRatio = 15 / 16;

  /// Maximum number of page dots shown at once, however many posts a Party has.
  static const maxVisibleDots = 5;

  /// Parties fetched per page in the feed.
  static const feedPageSize = 4;

  /// How many neighbouring posts (each side) are pre-loaded.
  static const preloadNeighbours = 1;

  /// A Party counts as "on screen" for auto-advance when at least this much
  /// of its media area is visible.
  static const activeVisibleFraction = 0.6;

  static const pageTransition = Duration(milliseconds: 320);
}
