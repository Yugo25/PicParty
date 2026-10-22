import 'package:intl/intl.dart';
import '../l10n/l10n.dart';

/// Human-readable times used across lists, in the viewer's local time zone.
class TimeFormat {
  TimeFormat._();

  /// How long ago something happened: `now`, `12m`, `3h`, `2d`, then `Oct 3`.
  static String ago(DateTime then, DateTime now) {
    final d = now.difference(then), l = L10n.current;
    if (d.inMinutes < 1) return l.agoNow;
    if (d.inMinutes < 60) return l.agoMinutes(d.inMinutes);
    if (d.inHours < 24) return l.agoHours(d.inHours);
    if (d.inDays < 7) return l.agoDays(d.inDays);
    final t = then.toLocal();
    return (t.year == now.toLocal().year ? DateFormat.MMMd(L10n.dateLocale) : DateFormat.yMMMd(L10n.dateLocale)).format(t);
  }

  /// A moment relative to today: `today at 18:38`, `tomorrow at 09:00`,
  /// `yesterday at 20:00`, `Oct 15 at 16:05`.
  static String dayAndTime(DateTime moment, DateTime now) {
    final t = moment.toLocal(), n = now.toLocal();
    final days = DateTime(t.year, t.month, t.day).difference(DateTime(n.year, n.month, n.day)).inDays;
    final time = DateFormat('HH:mm').format(t);
    final l = L10n.current;
    final day = switch (days) {
      0 => l.dayToday,
      1 => l.dayTomorrow,
      -1 => l.dayYesterday,
      _ => (t.year == n.year ? DateFormat.MMMd(L10n.dateLocale) : DateFormat.yMMMd(L10n.dateLocale)).format(t),
    };
    return l.dayAtTime(day, time);
  }

  /// A length of time in words: `6 hours`, `1 day 2 hours`, `45 minutes`.
  static String duration(Duration d) {
    final days = d.inDays, h = d.inHours % 24, m = d.inMinutes % 60;
    final l = L10n.current;
    final parts = [
      if (days > 0) l.durationDays(days),
      if (h > 0) l.durationHours(h),
      if (m > 0 && days == 0) l.durationMinutes(m),
    ];
    return parts.isEmpty ? l.durationUnderMinute : parts.join(' ');
  }

  /// `Jun 12, 2024` — used for memories (ended Parties).
  static String date(DateTime moment) => DateFormat.yMMMd(L10n.dateLocale).format(moment.toLocal());

  /// True when [moment] falls on the same local calendar day as [now].
  static bool isToday(DateTime moment, DateTime now) {
    final t = moment.toLocal(), n = now.toLocal();
    return t.year == n.year && t.month == n.month && t.day == n.day;
  }
}
