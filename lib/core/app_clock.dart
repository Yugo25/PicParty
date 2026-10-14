import 'dart:async';
import 'package:flutter/widgets.dart';

/// One shared 1 Hz clock for every countdown in the app.
///
/// Ticks are aligned to wall-clock second boundaries so all timers change
/// together. While the app is in the background the ticker stops; on resume the
/// value is refreshed immediately, so countdowns always reflect the real time.
class AppClock extends ValueNotifier<DateTime> {
  AppClock() : super(DateTime.now());
  static final instance = AppClock();

  Timer? _timer;
  AppLifecycleListener? _lifecycle;

  void start() {
    _lifecycle ??= AppLifecycleListener(
      onResume: _resume,
      onShow: _resume,
      onHide: _stop,
      onPause: _stop,
    );
    _resume();
  }

  void _resume() {
    value = DateTime.now();
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    final untilNextSecond = Duration(milliseconds: 1000 - now.millisecond);
    _timer = Timer(untilNextSecond, () {
      value = DateTime.now();
      _schedule();
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    _lifecycle?.dispose();
    super.dispose();
  }
}
