import 'package:flutter/widgets.dart';
import '../../core/app_clock.dart';

/// Rebuilds [builder] on each tick of the shared [AppClock] — but only while
/// this part of the tree is visible. When a route covers it (tickers muted),
/// it stops listening, and catches up with the real time when shown again.
///
/// Wrap the smallest possible subtree (just the timer text) so a tick never
/// rebuilds a whole card or screen.
class ClockBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, DateTime now) builder;
  const ClockBuilder({super.key, required this.builder});

  @override
  State<ClockBuilder> createState() => _ClockBuilderState();
}

class _ClockBuilderState extends State<ClockBuilder> {
  bool _listening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _listening) return;
    _listening = visible;
    visible ? AppClock.instance.addListener(_tick) : AppClock.instance.removeListener(_tick);
  }

  @override
  void dispose() {
    if (_listening) AppClock.instance.removeListener(_tick);
    super.dispose();
  }

  void _tick() => setState(() {});

  @override
  Widget build(BuildContext context) => widget.builder(context, AppClock.instance.value);
}
