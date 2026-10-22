import '../../models/countdown.dart';
import '../../models/feed/feed_author.dart';
import '../../models/feed/feed_party.dart';
import '../../models/feed/party_options.dart';
import '../mock/mock_network.dart';
import '../mock/mock_people.dart';
import '../mock_feed_repository.dart';
import 'explore_repository.dart';

/// Explore over the in-memory demo Parties and people.
class MockExploreRepository implements ExploreRepository {
  final MockFeedRepository _feed;
  MockExploreRepository([MockFeedRepository? feed]) : _feed = feed ?? MockFeedRepository.instance;

  @override
  Future<List<FeedParty>> parties(PartyQuery query, {required int page, required int pageSize}) async {
    await MockNetwork.request();
    final results = filterParties(_feed.all, query, DateTime.now());
    return results.skip(page * pageSize).take(pageSize).toList();
  }

  /// The search / filter / sort rules, kept pure so they can be tested.
  static List<FeedParty> filterParties(List<FeedParty> all, PartyQuery query, DateTime now) {
    final text = query.text.trim().toLowerCase();
    CountdownPhase phase(FeedParty p) => CountdownSnapshot.at(start: p.startAt, end: p.endAt, now: now).phase;

    final list = all.where((p) {
      if (p.privacy != PartyPrivacy.public) return false;
      if (query.category != null && p.category != query.category) return false;
      if (text.isNotEmpty) {
        final host = p.hostId == null ? null : MockPeople.byId(p.hostId!);
        final haystack = [p.title, p.description ?? '', p.category ?? '', host?.name ?? '', host?.username ?? ''].join(' ').toLowerCase();
        if (!haystack.contains(text)) return false;
      }
      final ph = phase(p);
      return switch (query.view) {
        PartyView.live || PartyView.endingSoon => ph == CountdownPhase.live,
        PartyView.trending || PartyView.newest => ph != CountdownPhase.closed,
        PartyView.everything => true,
      };
    }).toList();

    int byTrend(FeedParty a, FeedParty b) => b.trendScore.compareTo(a.trendScore);
    switch (query.view) {
      case PartyView.live:
      case PartyView.trending:
        list.sort(byTrend);
      case PartyView.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case PartyView.endingSoon:
        list.sort((a, b) => a.endAt.compareTo(b.endAt));
      case PartyView.everything:
        // Open Parties first (by popularity), then ended ones, most recent first.
        list.sort((a, b) {
          final ac = phase(a) == CountdownPhase.closed, bc = phase(b) == CountdownPhase.closed;
          if (ac != bc) return ac ? 1 : -1;
          return ac ? b.endAt.compareTo(a.endAt) : byTrend(a, b);
        });
    }
    return list;
  }

  @override
  Future<List<FeedAuthor>> people(String text, {required int page, required int pageSize}) async {
    await MockNetwork.request();
    final q = text.trim().toLowerCase();
    final list = MockPeople.others.where((p) => q.isEmpty || p.name.toLowerCase().contains(q) || p.username.toLowerCase().contains(q)).toList();
    return list.skip(page * pageSize).take(pageSize).toList();
  }
}
