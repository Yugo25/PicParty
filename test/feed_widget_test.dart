import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picparty/core/app_clock.dart';
import 'package:picparty/models/countdown.dart';
import 'package:picparty/models/feed/feed_author.dart';
import 'package:picparty/models/feed/feed_party.dart';
import 'package:picparty/models/feed/feed_post.dart';
import 'package:picparty/services/feed/active_party_controller.dart';
import 'package:picparty/theme/app_theme.dart';
import 'package:picparty/widgets/countdown/phase_builder.dart';
import 'package:picparty/widgets/countdown/photo_countdown_overlay.dart';
import 'package:picparty/widgets/feed/party_feed_item.dart';

FeedParty _party() {
  final now = DateTime.now();
  FeedPost post(int i, String user, String caption, int likes) => FeedPost(
        id: 'p$i',
        partyId: 'kyoto',
        author: FeedAuthor(id: 'u$i', username: user),
        type: FeedMediaType.photo,
        caption: caption,
        createdAt: now,
        reactions: PostReactions(likeCount: likes, commentCount: i),
      );
  return FeedParty(
    id: 'kyoto',
    title: 'Kyoto through our eyes',
    thumbnailUrl: (w, h) => 'https://example.invalid/$w/$h',
    contributorCount: 128,
    startAt: now.subtract(const Duration(hours: 1)),
    endAt: now.add(const Duration(hours: 6)),
    posts: [post(0, 'sarah.k', 'A quiet morning in Kyoto.', 124), post(1, 'kenjiro', 'An afternoon well spent.', 86)],
  );
}

void main() {
  testWidgets('swiping the photo changes the post but not the Party or timer', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final feed = ActivePartyController();
    addTearDown(feed.dispose);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: ListView(children: [PartyFeedItem(party: _party(), feed: feed)])),
    ));

    expect(find.text('@sarah.k'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('124'), findsOneWidget);
    final timerPos = tester.getCenter(find.text('UPLOADS CLOSE IN'));

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('@kenjiro'), findsOneWidget);
    expect(find.text('An afternoon well spent.'), findsOneWidget);
    expect(find.text('86'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('Kyoto through our eyes'), findsOneWidget);
    expect(tester.getCenter(find.text('UPLOADS CLOSE IN')), timerPos);
  });

  testWidgets('timer switches to Uploads closed at the deadline and uploads disable', (tester) async {
    final end = DateTime.now().add(const Duration(seconds: 3));
    final start = end.subtract(const Duration(hours: 1));
    AppClock.instance.value = end.subtract(const Duration(seconds: 2));
    var builds = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          SizedBox(height: 300, child: PhotoCountdownOverlay(startAt: start, endAt: end)),
          PhaseBuilder(
            startAt: start,
            endAt: end,
            builder: (context, phase) {
              builds++;
              return Text(phase == CountdownPhase.live ? 'upload enabled' : 'upload disabled');
            },
          ),
        ]),
      ),
    ));
    expect(find.text('00:00:02'), findsOneWidget);
    expect(find.text('upload enabled'), findsOneWidget);

    AppClock.instance.value = end.subtract(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('00:00:01'), findsOneWidget);
    expect(builds, 1, reason: 'phase builder must not rebuild on every tick');

    AppClock.instance.value = end.add(const Duration(seconds: 5));
    await tester.pump();
    expect(find.text('Uploads closed'), findsOneWidget);
    expect(find.text('PARTY ENDED'), findsOneWidget);
    expect(find.text('upload disabled'), findsOneWidget);
    expect(find.textContaining('-'), findsNothing);
  });
}
