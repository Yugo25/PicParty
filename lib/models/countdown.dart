import 'package:intl/intl.dart';

/// Where a Party is in its life cycle, relative to "now".
enum CountdownPhase { upcoming, live, closed }

/// UI-independent countdown state for a Party.
///
/// Everything here is a pure function of (start, end, now), so the same data
/// can drive the in-feed timer today and home-screen widgets / notifications
/// later, each with its own look.
class CountdownSnapshot {
  final CountdownPhase phase;

  /// Time until the next boundary (start when upcoming, end when live).
  /// Always zero once closed — never negative.
  final Duration remaining;

  /// The moment the current phase ends (start or end), or the end for closed.
  final DateTime target;

  const CountdownSnapshot._(this.phase, this.remaining, this.target);

  factory CountdownSnapshot.at({required DateTime start, required DateTime end, required DateTime now}) {
    if (now.isBefore(start)) return CountdownSnapshot._(CountdownPhase.upcoming, start.difference(now), start);
    if (now.isBefore(end)) return CountdownSnapshot._(CountdownPhase.live, end.difference(now), end);
    return CountdownSnapshot._(CountdownPhase.closed, Duration.zero, end);
  }

  bool get acceptsUploads => phase == CountdownPhase.live;

  String get label => switch (phase) {
        CountdownPhase.upcoming => 'STARTS IN',
        CountdownPhase.live => 'UPLOADS CLOSE IN',
        CountdownPhase.closed => 'PARTY ENDED',
      };

  /// The big number, e.g. `06:24:18`, or `2d 06:24` when a day or more is left.
  /// Closed Parties show `Uploads closed` instead of a time.
  String get display => phase == CountdownPhase.closed ? 'Uploads closed' : formatRemaining(remaining);

  static String formatRemaining(Duration d) {
    final s = d.isNegative ? 0 : d.inSeconds;
    final days = s ~/ 86400, h = (s % 86400) ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return days > 0 ? '${days}d ${two(h)}:${two(m)}' : '${two(h)}:${two(m)}:${two(sec)}';
  }

  /// Small line under the timer, in the viewer's local time:
  /// `Today, 16:05`, `Tomorrow, 09:00`, `Oct 15, 16:05`, or `Ended Oct 12, 20:00`.
  String targetLabel(DateTime now) {
    final when = formatMoment(target, now);
    return phase == CountdownPhase.closed ? 'Ended $when' : when;
  }

  static String formatMoment(DateTime moment, DateTime now) {
    final t = moment.toLocal(), n = now.toLocal();
    final day = DateTime(t.year, t.month, t.day), today = DateTime(n.year, n.month, n.day);
    final time = DateFormat('HH:mm').format(t);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Today, $time';
    if (diff == 1) return 'Tomorrow, $time';
    if (diff == -1) return 'Yesterday, $time';
    return DateFormat(t.year == n.year ? 'MMM d, HH:mm' : 'MMM d y, HH:mm').format(t);
  }
}
