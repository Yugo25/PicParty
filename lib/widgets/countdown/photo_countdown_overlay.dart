import 'package:flutter/material.dart';
import '../../core/app_clock.dart';
import '../../models/countdown.dart';
import 'countdown_style.dart';

/// The Party timer drawn on top of a post's photo.
///
/// Only this widget listens to the 1 Hz clock, and it sits behind a
/// [RepaintBoundary], so the photo and the rest of the feed are not rebuilt or
/// repainted every second. It ignores touches so swipes reach the photo.
class PhotoCountdownOverlay extends StatelessWidget {
  final DateTime startAt, endAt;
  final CountdownStyle style;

  const PhotoCountdownOverlay({super.key, required this.startAt, required this.endAt, this.style = CountdownStyle.overlay});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: style.alignment,
        child: RepaintBoundary(
          child: ValueListenableBuilder<DateTime>(
            valueListenable: AppClock.instance,
            builder: (context, now, _) {
              final snap = CountdownSnapshot.at(start: startAt, end: endAt, now: now);
              final closed = snap.phase == CountdownPhase.closed;
              return Semantics(
                liveRegion: false,
                label: '${snap.label} ${snap.display}, ${snap.targetLabel(now)}',
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(snap.label, style: style.labelStyle),
                      SizedBox(height: style.labelGap),
                      Text(snap.display, style: closed ? style.closedStyle : style.digitsStyle, maxLines: 1),
                      SizedBox(height: style.targetGap),
                      Text(snap.targetLabel(now), style: style.targetStyle),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
