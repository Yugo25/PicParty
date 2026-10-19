import '../../models/feed/feed_author.dart';
import '../../models/feed/feed_party.dart';
import 'mock_explore_repository.dart';
import '../../l10n/l10n.dart';

/// Which Parties Explore lists, and in what order.
enum PartyView {
  /// Running now (uploads open), most popular first.
  live,

  /// Most popular Parties that have not ended.
  trending,

  /// Newest first, by creation time, not ended.
  newest,

  /// Running now, closing soonest first.
  endingSoon,

  /// Everything, including Parties that have ended.
  everything;

  String get label => switch (this) {
        PartyView.live => L10n.current.viewLive,
        PartyView.trending => L10n.current.viewTrending,
        PartyView.newest => L10n.current.viewNewest,
        PartyView.endingSoon => L10n.current.viewEndingSoon,
        PartyView.everything => L10n.current.viewEverything,
      };

  String get description => switch (this) {
        PartyView.live => L10n.current.viewLiveDescription,
        PartyView.trending => L10n.current.viewTrendingDescription,
        PartyView.newest => L10n.current.viewNewestDescription,
        PartyView.endingSoon => L10n.current.viewEndingSoonDescription,
        PartyView.everything => L10n.current.viewEverythingDescription,
      };
}

/// A Party search in Explore.
class PartyQuery {
  final String text;
  final PartyView view;

  /// A category id, or null for all.
  final String? category;

  const PartyQuery({this.text = '', this.view = PartyView.live, this.category});

  PartyQuery copyWith({String? text, PartyView? view, String? category, bool clearCategory = false}) => PartyQuery(
        text: text ?? this.text,
        view: view ?? this.view,
        category: clearCategory ? null : (category ?? this.category),
      );

  @override
  bool operator ==(Object other) => other is PartyQuery && other.text == text && other.view == view && other.category == category;

  @override
  int get hashCode => Object.hash(text, view, category);
}

/// Search and discovery. Only public Parties are ever returned.
abstract class ExploreRepository {
  /// The repository the app uses. Swap for an API-backed one later.
  static ExploreRepository instance = MockExploreRepository();

  Future<List<FeedParty>> parties(PartyQuery query, {required int page, required int pageSize});

  Future<List<FeedAuthor>> people(String text, {required int page, required int pageSize});
}
