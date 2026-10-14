import '../../models/feed/feed_author.dart';
import '../../models/feed/feed_party.dart';
import 'mock_explore_repository.dart';

/// Which Parties Explore lists, and in what order.
enum PartyView {
  /// Running now (uploads open), most popular first.
  live('Live', 'Running now — uploads are open'),

  /// Most popular Parties that have not ended.
  trending('Trending', 'Popular Parties that haven\'t ended'),

  /// Newest first, by creation time, not ended.
  newest('New', 'Recently created, not ended'),

  /// Running now, closing soonest first.
  endingSoon('Ending soon', 'Running now, closing soonest first'),

  /// Everything, including Parties that have ended.
  everything('Everything', 'Includes upcoming and ended Parties');

  final String label, description;
  const PartyView(this.label, this.description);
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
