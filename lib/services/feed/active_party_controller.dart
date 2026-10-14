import 'package:flutter/widgets.dart';
import '../../config/feed_config.dart';

/// Decides which single Party in the feed is "active" — the one mostly on
/// screen — and whether the feed as a whole is suspended (app in background,
/// a sheet or detail screen open). Only an active, non-suspended Party may
/// auto-advance or play video.
class ActivePartyController {
  final activeId = ValueNotifier<String?>(null);
  final suspended = ValueNotifier<bool>(false);

  final _mediaKeys = <String, GlobalKey>{};
  final _suspendReasons = <Object>{};
  late final AppLifecycleListener _lifecycle;
  static const _backgroundReason = 'background';

  /// Key of the scrollable's viewport, used to measure visibility.
  final viewportKey = GlobalKey();

  ActivePartyController() {
    _lifecycle = AppLifecycleListener(
      onHide: () => suspend(_backgroundReason),
      onPause: () => suspend(_backgroundReason),
      onShow: () => resume(_backgroundReason),
      onResume: () => resume(_backgroundReason),
    );
  }

  /// Registers the media area of a Party so its visibility can be measured.
  GlobalKey keyFor(String partyId) => _mediaKeys.putIfAbsent(partyId, () => GlobalKey(debugLabel: 'media-$partyId'));

  void unregister(String partyId) {
    _mediaKeys.remove(partyId);
    if (activeId.value == partyId) activeId.value = null;
  }

  void suspend(Object reason) {
    _suspendReasons.add(reason);
    suspended.value = true;
  }

  void resume(Object reason) {
    _suspendReasons.remove(reason);
    suspended.value = _suspendReasons.isNotEmpty;
  }

  /// Suspends playback while [future] (e.g. a pushed route or sheet) is open.
  Future<T> suspendWhile<T>(Future<T> future) async {
    final token = Object();
    suspend(token);
    try {
      return await future;
    } finally {
      resume(token);
    }
  }

  /// Re-measures which Party is mostly visible. Call after scroll and layout.
  void recompute() {
    final viewportBox = viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null || !viewportBox.hasSize) return;
    final viewport = viewportBox.localToGlobal(Offset.zero) & viewportBox.size;

    String? best;
    var bestFraction = 0.0;
    _mediaKeys.forEach((id, key) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached || !box.hasSize || box.size.height == 0) return;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      final visible = rect.intersect(viewport);
      final fraction = visible.isEmpty || visible.height <= 0 ? 0.0 : visible.height / rect.height;
      if (fraction > bestFraction) {
        bestFraction = fraction;
        best = id;
      }
    });
    activeId.value = bestFraction >= FeedConfig.activeVisibleFraction ? best : null;
  }

  void dispose() {
    _lifecycle.dispose();
    activeId.dispose();
    suspended.dispose();
  }
}
