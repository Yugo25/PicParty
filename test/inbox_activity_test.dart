import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picparty/screens/inbox/activity_tab.dart';
import 'package:picparty/services/mock_feed_repository.dart';
import 'package:picparty/theme/app_theme.dart';

void main() {
  testWidgets('reminders describe the Party as it is now, and invites can be answered', (tester) async {
    tester.view.physicalSize = const Size(390, 2400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const Scaffold(body: ActivityTab())));
    await tester.pump(const Duration(milliseconds: 400));

    // The ended Party's reminder no longer claims time is left.
    expect(find.textContaining('Autumn walks has ended', findRichText: true), findsOneWidget);
    expect(find.textContaining('ends in 30 min', findRichText: true), findsNothing);
    // A running Party's reminder gives its real closing time.
    expect(find.textContaining(RegExp(r'Coffee break closes (today|tomorrow) at \d\d:\d\d'), findRichText: true), findsOneWidget);

    // Accepting the private Party invite grants access.
    final feed = MockFeedRepository.instance;
    expect(feed.canView(feed.party('montreal')!), isFalse);
    await tester.tap(find.text('Accept').first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('You joined this Party'), findsOneWidget);
    expect(feed.canView(feed.party('montreal')!), isTrue);

    // Filters narrow the list.
    await tester.tap(find.text('Invites'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('invited you to', findRichText: true), findsWidgets);
    expect(find.textContaining('liked your photo', findRichText: true), findsNothing);
    expect(find.textContaining('started following you', findRichText: true), findsNothing);
  });
}
