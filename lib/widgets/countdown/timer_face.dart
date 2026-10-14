import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/countdown.dart';
import '../../models/feed/party_options.dart';
import 'countdown_style.dart';

/// The Party timer drawn on a photo, for a given moment — no clock of its own.
///
/// [PhotoCountdownOverlay] feeds it the live time; the create form feeds it a
/// fixed "at the start" moment for its preview.
class TimerFace extends StatelessWidget {
  final CountdownSnapshot snapshot;
  final TimerStyle timerStyle;
  final CountdownStyle style;

  /// Share of the Party left, for [TimerStyle.ring] (1 → 0).
  final double fractionLeft;

  /// Small line under the timer (deadline, or "Preview").
  final String? caption;

  const TimerFace({
    super.key,
    required this.snapshot,
    this.timerStyle = TimerStyle.digital,
    this.style = CountdownStyle.overlay,
    this.fractionLeft = 1,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final closed = snapshot.phase == CountdownPhase.closed;
    final Widget main;
    if (closed) {
      main = Text(snapshot.display, style: style.closedStyle, maxLines: 1);
    } else {
      main = switch (timerStyle) {
        TimerStyle.digital => Text(snapshot.display, style: style.digitsStyle, maxLines: 1),
        TimerStyle.minimal => Text(CountdownSnapshot.formatMinimal(snapshot.remaining), style: style.digitsStyle, maxLines: 1),
        TimerStyle.ring => TimerRing(
            fraction: fractionLeft,
            size: style.digitsStyle.fontSize! * 2.4,
            color: Colors.white,
            child: Text(
              CountdownSnapshot.formatMinimal(snapshot.remaining),
              style: style.digitsStyle.copyWith(fontSize: style.digitsStyle.fontSize! * 0.5),
              maxLines: 1,
            ),
          ),
      };
    }
    return Semantics(
      label: '${snapshot.label} ${snapshot.display}${caption == null ? '' : ', $caption'}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(snapshot.label, style: style.labelStyle),
            SizedBox(height: timerStyle == TimerStyle.ring && !closed ? 8 : style.labelGap),
            main,
            if (caption != null) ...[
              SizedBox(height: timerStyle == TimerStyle.ring && !closed ? 8 : style.targetGap),
              Text(caption!, style: style.targetStyle),
            ],
          ],
        ),
      ),
    );
  }
}

/// A circular "time left" ring with content in the middle.
class TimerRing extends StatelessWidget {
  final double fraction, size;
  final Color color;
  final Widget child;
  final double strokeWidth;

  const TimerRing({super.key, required this.fraction, required this.size, required this.color, required this.child, this.strokeWidth = 5});

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(fraction: fraction, color: color, strokeWidth: strokeWidth),
          child: Center(child: child),
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double fraction, strokeWidth;
  final Color color;
  _RingPainter({required this.fraction, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(strokeWidth / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color.withValues(alpha: 0.28);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawOval(r, track);
    if (fraction > 0) canvas.drawArc(r, -math.pi / 2, 2 * math.pi * fraction.clamp(0, 1), false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction || old.color != color || old.strokeWidth != strokeWidth;
}
