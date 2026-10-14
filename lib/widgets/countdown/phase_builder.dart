import 'package:flutter/material.dart';
import '../../core/app_clock.dart';
import '../../models/countdown.dart';

/// Rebuilds [builder] only when a Party moves between upcoming / live / closed,
/// not on every clock tick. Use it for things like enabling uploads.
class PhaseBuilder extends StatefulWidget {
  final DateTime startAt, endAt;
  final Widget Function(BuildContext context, CountdownPhase phase) builder;

  const PhaseBuilder({super.key, required this.startAt, required this.endAt, required this.builder});

  @override
  State<PhaseBuilder> createState() => _PhaseBuilderState();
}

class _PhaseBuilderState extends State<PhaseBuilder> {
  late CountdownPhase _phase = _compute();

  CountdownPhase _compute() =>
      CountdownSnapshot.at(start: widget.startAt, end: widget.endAt, now: AppClock.instance.value).phase;

  @override
  void initState() {
    super.initState();
    AppClock.instance.addListener(_onTick);
  }

  @override
  void didUpdateWidget(PhaseBuilder old) {
    super.didUpdateWidget(old);
    _phase = _compute();
  }

  @override
  void dispose() {
    AppClock.instance.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    final next = _compute();
    if (next != _phase) setState(() => _phase = next);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _phase);
}
