import 'feed_post.dart';

/// A Party as shown in the home feed: shared deadline plus its posts.
class FeedParty {
  final String id;
  final String title;
  final SizedImageUrl thumbnailUrl;
  final int contributorCount;
  final DateTime startAt, endAt;
  final bool fromFollowing;

  /// Posts, newest first. Only metadata lives here; media is loaded lazily by
  /// the widgets that show it.
  final List<FeedPost> posts;

  FeedParty({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.contributorCount,
    required this.startAt,
    required this.endAt,
    required this.posts,
    this.fromFollowing = false,
  });

  String get shareUrl => 'https://picparty.app/p/$id';
}
