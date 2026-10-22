import 'package:flutter/material.dart';
import '../../models/countdown.dart';
import '../../models/feed/party_options.dart';
import 'clock_builder.dart';
import 'countdown_style.dart';
import 'timer_face.dart';

/// The Party timer drawn on top of a post's photo.
///
/// Only this widget listens to the 1 Hz clock, and it sits behind a
/// [RepaintBoundary], so the photo and the rest of the feed are not rebuilt or
/// repainted every second. It ignores touches so swipes reach the photo.
class PhotoCountdownOverlay extends StatelessWidget {
  final DateTime startAt, endAt;
  final CountdownStyle style;
  final TimerStyle timerStyle;

  const PhotoCountdownOverlay({
    super.key,
    required this.startAt,
    required this.endAt,
    this.style = CountdownStyle.overlay,
    this.timerStyle = TimerStyle.digital,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: style.alignment,
        child: RepaintBoundary(
          child: ClockBuilder(
            builder: (context, now) {
              final snap = CountdownSnapshot.at(start: startAt, end: endAt, now: now);
              return TimerFace(
                snapshot: snap,
                timerStyle: timerStyle,
                style: style,
                fractionLeft: CountdownSnapshot.fractionLeft(start: startAt, end: endAt, now: now),
                caption: snap.targetLabel(now),
              );
            },
          ),
        ),
      ),
    );
  }
}
