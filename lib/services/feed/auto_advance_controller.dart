import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../config/feed_config.dart';

/// Auto-advance of the background posts inside one Party.
///
/// Off by default; the play button turns it on. It only runs while the Party
/// is active (mostly on screen, app in foreground, no sheet/detail open).
/// Photos advance on a fixed interval; videos advance when they finish, so the
/// photo timer never cuts a video short. A manual swipe turns it off.
///
/// This is independent of the Party countdown, which keeps running regardless.
class AutoAdvanceController extends ChangeNotifier {
  final VoidCallback onAdvance;
  final Duration photoInterval;

  AutoAdvanceController({required this.onAdvance, this.photoInterval = FeedConfig.photoAutoAdvanceInterval});

  bool _enabled = false;
  bool _active = false;
  bool _currentIsVideo = false;
  Timer? _timer;

  /// Whether the user has turned auto-advance on (drives the play/pause icon).
  bool get enabled => _enabled;

  /// Whether it is actually advancing right now.
  bool get running => _enabled && _active;

  void toggle() => setEnabled(!_enabled);

  void setEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    _restart();
    notifyListeners();
  }

  /// Visible-and-not-suspended state, set by the feed.
  void setActive(bool value) {
    if (_active == value) return;
    _active = value;
    _restart();
    notifyListeners();
  }

  /// Call whenever the shown post changes (by swipe or by auto-advance).
  void onPostShown({required bool isVideo}) {
    _currentIsVideo = isVideo;
    _restart();
  }

  /// A manual swipe pauses auto-advance so it never fights the user.
  void onUserSwipe() => setEnabled(false);

  /// The current video reached its end.
  void onVideoCompleted() {
    if (running && _currentIsVideo) onAdvance();
  }

  void _restart() {
    _timer?.cancel();
    _timer = null;
    if (running && !_currentIsVideo) {
      _timer = Timer(photoInterval, onAdvance);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
