import 'package:flutter/foundation.dart';

/// Ensures at most one feed video plays at a time.
///
/// A video view calls [claim] before playing; whoever held playback before is
/// told to stop through the callback it registered.
class VideoPlaybackCoordinator {
  VideoPlaybackCoordinator._();
  static final instance = VideoPlaybackCoordinator._();

  Object? _owner;
  VoidCallback? _stopOwner;

  void claim(Object owner, VoidCallback stop) {
    if (!identical(_owner, owner)) _stopOwner?.call();
    _owner = owner;
    _stopOwner = stop;
  }

  void release(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _stopOwner = null;
  }
}
