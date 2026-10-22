import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_config.dart';
import '../../models/comment.dart';
import '../../models/feed/feed_party.dart';
import '../../models/feed/feed_post.dart';
import '../../models/feed/party_options.dart';
import '../mock_feed_repository.dart';
import 'supabase_feed_repository.dart';

enum FeedTab { forYou, following }

/// A profile's Parties and posts, already limited to what the viewer may see.
class ProfileParties {
  final List<FeedParty> hosted, joined;
  final List<FeedPost> posts;
  const ProfileParties({required this.hosted, required this.joined, required this.posts});
}

/// Parties, posts, likes and comments. Notifies when a Party changes (a new
/// post, a refreshed Party), so open screens can redraw.
abstract class FeedRepository extends ChangeNotifier {
  /// Demo data without a backend; Supabase otherwise.
  static FeedRepository instance = AppConfig.demoMode ? MockFeedRepository.instance : SupabaseFeedRepository();

  /// One page of the home feed.
  Future<List<FeedParty>> fetchParties({required FeedTab tab, required int page, required int pageSize});

  /// A Party that has already been loaded, without waiting.
  FeedParty? party(String id);

  /// Fetches a Party with all of its posts. Null when it doesn't exist.
  Future<FeedParty?> loadParty(String id);

  /// False for a private Party the current user is not a member of.
  bool canView(FeedParty party);

  Future<ProfileParties> partiesOf(String userId);

  /// Likes or unlikes right away; rolls back if the request fails.
  Future<void> toggleLike(FeedPost post);

  /// Oldest first.
  Future<List<Comment>> comments(FeedPost post);

  Future<void> addComment(FeedPost post, String text);

  /// Posts a photo to a live Party, joining it first if needed.
  Future<void> addPhoto(FeedParty party, XFile file);

  Future<FeedParty> createParty({
    required String title,
    String? description,
    String? category,
    required PartyPrivacy privacy,
    required TimerStyle timerStyle,
    required DateTime startAt,
    required Duration duration,
    XFile? cover,
  });

  /// Forgets loaded Parties after signing out or switching accounts.
  void clearCache() {}
}
