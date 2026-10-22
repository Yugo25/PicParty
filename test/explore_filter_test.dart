import 'package:flutter_test/flutter_test.dart';
import 'package:picparty/models/feed/feed_party.dart';
import 'package:picparty/models/feed/party_options.dart';
import 'package:picparty/services/explore/explore_repository.dart';
import 'package:picparty/services/explore/mock_explore_repository.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);

  FeedParty party(String id, {required Duration startOffset, required Duration endOffset, String category = 'travel', int trend = 0,
          PartyPrivacy privacy = PartyPrivacy.public, Duration created = Duration.zero}) =>
      FeedParty(
        id: id,
        title: 'Party $id',
        category: category,
        contributorCount: 1,
        startAt: now.add(startOffset),
        endAt: now.add(endOffset),
        createdAt: now.subtract(created),
        posts: [],
        privacy: privacy,
        trendScore: trend,
      );

  final all = [
    party('live-late', startOffset: const Duration(hours: -1), endOffset: const Duration(hours: 9), trend: 10, created: const Duration(hours: 3)),
    party('live-soon', startOffset: const Duration(hours: -1), endOffset: const Duration(minutes: 20), trend: 50, category: 'food', created: const Duration(hours: 5)),
    party('upcoming', startOffset: const Duration(hours: 2), endOffset: const Duration(hours: 8), trend: 90, created: const Duration(hours: 1)),
    party('ended', startOffset: const Duration(hours: -9), endOffset: const Duration(hours: -1), trend: 99, created: const Duration(hours: 10)),
    party('private', startOffset: const Duration(hours: -1), endOffset: const Duration(hours: 3), privacy: PartyPrivacy.private, trend: 80),
    party('unlisted', startOffset: const Duration(hours: -1), endOffset: const Duration(hours: 3), privacy: PartyPrivacy.unlisted, trend: 70),
  ];

  List<String> ids(PartyQuery q) => MockExploreRepository.filterParties(all, q, now).map((p) => p.id).toList();

  test('Live shows only running Parties — never ended or upcoming ones', () {
    expect(ids(const PartyQuery(view: PartyView.live)), ['live-soon', 'live-late']);
  });

  test('Ending soon lists running Parties, closing soonest first', () {
    expect(ids(const PartyQuery(view: PartyView.endingSoon)), ['live-soon', 'live-late']);
  });

  test('New sorts by creation time and leaves out ended Parties', () {
    expect(ids(const PartyQuery(view: PartyView.newest)), ['upcoming', 'live-late', 'live-soon']);
  });

  test('Trending ranks by score without ended Parties', () {
    expect(ids(const PartyQuery(view: PartyView.trending)), ['upcoming', 'live-soon', 'live-late']);
  });

  test('Everything includes ended Parties, after open ones', () {
    expect(ids(const PartyQuery(view: PartyView.everything)), ['upcoming', 'live-soon', 'live-late', 'ended']);
  });

  test('private and unlisted Parties never appear in Explore', () {
    final found = ids(const PartyQuery(view: PartyView.everything));
    expect(found, isNot(contains('private')));
    expect(found, isNot(contains('unlisted')));
  });

  test('category and text filters combine', () {
    expect(ids(const PartyQuery(view: PartyView.everything, category: 'food')), ['live-soon']);
    expect(ids(const PartyQuery(view: PartyView.everything, text: 'late')), ['live-late']);
  });
}
