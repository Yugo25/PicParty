import 'package:intl/intl.dart';

/// Human-readable times used across lists, in the viewer's local time zone.
class TimeFormat {
  TimeFormat._();

  /// How long ago something happened: `now`, `12m`, `3h`, `2d`, then `Oct 3`.
  static String ago(DateTime then, DateTime now) {
    final d = now.difference(then);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    final t = then.toLocal();
    return DateFormat(t.year == now.toLocal().year ? 'MMM d' : 'MMM d, y').format(t);
  }

  /// A moment relative to today: `today at 18:38`, `tomorrow at 09:00`,
  /// `yesterday at 20:00`, `Oct 15 at 16:05`.
  static String dayAndTime(DateTime moment, DateTime now) {
    final t = moment.toLocal(), n = now.toLocal();
    final days = DateTime(t.year, t.month, t.day).difference(DateTime(n.year, n.month, n.day)).inDays;
    final time = DateFormat('HH:mm').format(t);
    final day = switch (days) {
      0 => 'today',
      1 => 'tomorrow',
      -1 => 'yesterday',
      _ => DateFormat(t.year == n.year ? 'MMM d' : 'MMM d, y').format(t),
    };
    return '$day at $time';
  }

  /// A length of time in words: `6 hours`, `1 day 2 hours`, `45 minutes`.
  static String duration(Duration d) {
    final days = d.inDays, h = d.inHours % 24, m = d.inMinutes % 60;
    String unit(int v, String name) => '$v $name${v == 1 ? '' : 's'}';
    final parts = [
      if (days > 0) unit(days, 'day'),
      if (h > 0) unit(h, 'hour'),
      if (m > 0 && days == 0) unit(m, 'minute'),
    ];
    return parts.isEmpty ? 'less than a minute' : parts.join(' ');
  }

  /// `Jun 12, 2024` — used for memories (ended Parties).
  static String date(DateTime moment) => DateFormat('MMM d, y').format(moment.toLocal());

  /// True when [moment] falls on the same local calendar day as [now].
  static bool isToday(DateTime moment, DateTime now) {
    final t = moment.toLocal(), n = now.toLocal();
    return t.year == n.year && t.month == n.month && t.day == n.day;
  }
}
