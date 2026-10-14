import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:picparty/screens/create_party/create_party_screen.dart';
import 'package:picparty/services/mock_feed_repository.dart';
import 'package:picparty/theme/app_theme.dart';

void main() {
  testWidgets('create flow: validation, kept input, live preview, single submit', (tester) async {
    tester.view.physicalSize = const Size(390, 1800) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final router = GoRouter(initialLocation: '/create', routes: [
      GoRoute(path: '/create', builder: (c, s) => const CreatePartyScreen()),
      GoRoute(path: '/p/:id', builder: (c, s) => Scaffold(body: Text('opened ${s.pathParameters['id']}'))),
    ]);
    await tester.pumpWidget(MaterialApp.router(theme: AppTheme.light(), routerConfig: router));

    // Step 1: a title is required.
    expect(find.text('1 of 2'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Add a title for your Party.'), findsOneWidget);
    expect(find.text('1 of 2'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Montreal after hours');
    await tester.enterText(find.byType(TextField).at(1), 'Little moments after sunset.');
    await tester.tap(find.text('Private'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2: preview shows the start state with the default 6h.
    expect(find.text('2 of 2'), findsOneWidget);
    expect(find.text('UPLOADS CLOSE IN'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('06:00:00'), findsNWidgets(2)); // preview + Digital tile

    // Custom duration out of range shows an error next to the fields.
    await tester.tap(find.text('Custom'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(0), '31'); // Days
    await tester.pump();
    expect(find.text('A Party can last up to 30 days.'), findsOneWidget);

    // Going back keeps what was typed.
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(find.text('Montreal after hours'), findsOneWidget);
    expect(find.text('Little moments after sunset.'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('31'), findsOneWidget);

    // Fix the duration and switch the style: the preview follows at once.
    await tester.enterText(find.text('31'), '0');
    await tester.pump();
    expect(find.text('A Party can last up to 30 days.'), findsNothing);
    await tester.tap(find.text('Minimal'));
    await tester.pump();
    expect(find.text('6h'), findsWidgets);
    expect(find.text('06:00:00'), findsOneWidget); // only the Digital tile now

    // Create: the button disables while sending, then opens the new Party.
    final before = MockFeedRepository.instance.all.length;
    await tester.tap(find.byIcon(Icons.celebration_outlined));
    await tester.pump();
    expect(find.text('Creating…'), findsOneWidget);
    await tester.tap(find.text('Creating…'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(MockFeedRepository.instance.all.length, before + 1);
    final created = MockFeedRepository.instance.all.first;
    expect(created.title, 'Montreal after hours');
    expect(created.duration, const Duration(hours: 6));
    expect(created.privacy.name, 'private');
    expect(created.timerStyle.name, 'minimal');
    expect(find.text('opened ${created.id}'), findsOneWidget);
  });
}
