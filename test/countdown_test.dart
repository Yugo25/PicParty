import 'package:flutter_test/flutter_test.dart';
import 'package:picparty/models/countdown.dart';

void main() {
  final start = DateTime(2026, 10, 13, 10);
  final end = DateTime(2026, 10, 13, 16, 5);

  test('phase follows start and end', () {
    expect(CountdownSnapshot.at(start: start, end: end, now: DateTime(2026, 10, 13, 9)).phase, CountdownPhase.upcoming);
    expect(CountdownSnapshot.at(start: start, end: end, now: DateTime(2026, 10, 13, 12)).phase, CountdownPhase.live);
    expect(CountdownSnapshot.at(start: start, end: end, now: end).phase, CountdownPhase.closed);
  });

  test('labels per phase', () {
    expect(CountdownSnapshot.at(start: start, end: end, now: DateTime(2026, 10, 13, 9)).label, 'STARTS IN');
    expect(CountdownSnapshot.at(start: start, end: end, now: DateTime(2026, 10, 13, 12)).label, 'UPLOADS CLOSE IN');
    expect(CountdownSnapshot.at(start: start, end: end, now: DateTime(2026, 10, 14)).display, 'Uploads closed');
  });

  test('remaining is formatted with and without days', () {
    expect(CountdownSnapshot.formatRemaining(const Duration(hours: 6, minutes: 24, seconds: 18)), '06:24:18');
    expect(CountdownSnapshot.formatRemaining(const Duration(days: 2, hours: 6, minutes: 24, seconds: 59)), '2d 06:24');
    expect(CountdownSnapshot.formatRemaining(const Duration(seconds: -5)), '00:00:00');
  });

  test('never negative after the end', () {
    final snap = CountdownSnapshot.at(start: start, end: end, now: end.add(const Duration(hours: 3)));
    expect(snap.remaining, Duration.zero);
    expect(snap.acceptsUploads, isFalse);
  });

  test('moment labels', () {
    final now = DateTime(2026, 10, 13, 9, 41);
    expect(CountdownSnapshot.formatMoment(DateTime(2026, 10, 13, 16, 5), now), 'Today, 16:05');
    expect(CountdownSnapshot.formatMoment(DateTime(2026, 10, 14, 9), now), 'Tomorrow, 09:00');
    expect(CountdownSnapshot.formatMoment(DateTime(2026, 10, 15, 16, 5), now), 'Oct 15, 16:05');
    final closed = CountdownSnapshot.at(start: start, end: end, now: DateTime(2026, 10, 14, 8));
    expect(closed.targetLabel(DateTime(2026, 10, 14, 8)), 'Ended Yesterday, 16:05');
  });

  test('card and minimal formats', () {
    expect(CountdownSnapshot.formatCompact(const Duration(hours: 1, minutes: 59, seconds: 34)), '01:59:34');
    expect(CountdownSnapshot.formatCompact(const Duration(days: 1, hours: 6, minutes: 40)), '1d 06h');
    expect(CountdownSnapshot.formatMinimal(const Duration(hours: 6)), '6h');
    expect(CountdownSnapshot.formatMinimal(const Duration(hours: 5, minutes: 59, seconds: 30)), '5h 59m');
    expect(CountdownSnapshot.formatMinimal(const Duration(days: 2, hours: 6)), '2d 6h');
    expect(CountdownSnapshot.formatMinimal(const Duration(minutes: 42)), '42m');
    expect(CountdownSnapshot.formatMinimal(const Duration(seconds: -3)), '0s');
  });

  test('ring fraction is full before the start and empty after the end', () {
    expect(CountdownSnapshot.fractionLeft(start: start, end: end, now: DateTime(2026, 10, 13, 9)), 1);
    expect(CountdownSnapshot.fractionLeft(start: start, end: end, now: start), 1);
    expect(CountdownSnapshot.fractionLeft(start: start, end: end, now: end), 0);
    final mid = start.add(end.difference(start) ~/ 2);
    expect(CountdownSnapshot.fractionLeft(start: start, end: end, now: mid), closeTo(0.5, 0.001));
  });
}
