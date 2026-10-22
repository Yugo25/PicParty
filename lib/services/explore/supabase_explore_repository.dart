import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../models/feed/feed_author.dart';
import '../../models/feed/feed_party.dart';
import '../feed/feed_repository.dart';
import '../feed/supabase_feed_repository.dart';
import 'explore_repository.dart';

/// Explore over the shared Parties and people in Supabase.
class SupabaseExploreRepository implements ExploreRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  @override
  Future<List<FeedParty>> parties(PartyQuery query, {required int page, required int pageSize}) =>
      (FeedRepository.instance as SupabaseFeedRepository).queryParties(
        view: switch (query.view) {
          PartyView.live => 'live',
          PartyView.trending => 'trending',
          PartyView.newest => 'newest',
          PartyView.endingSoon => 'ending_soon',
          PartyView.everything => 'everything',
        },
        text: query.text,
        category: query.category,
        limit: pageSize,
        offset: page * pageSize,
      );

  @override
  Future<List<FeedAuthor>> people(String text, {required int page, required int pageSize}) async {
    final rows = await _client.rpc('search_people', params: {'p_text': text, 'p_limit': pageSize, 'p_offset': page * pageSize}) as List;
    return [
      for (final r in rows)
        FeedAuthor(
          id: r['id'] as String,
          username: r['username'] as String,
          displayName: r['display_name'] as String?,
          avatarUrl: r['avatar_url'] as String?,
        ),
    ];
  }
}
