import 'feed_post.dart';
import 'party_options.dart';

/// A Party as shown in the app: shared deadline, settings and its posts.
class FeedParty {
  final String id;
  final String title;
  final String? description;

  /// One of [PartyCategories.ids], or null.
  final String? category;

  /// Cover image at a requested pixel size. Shown until the first post exists.
  final SizedImageUrl? thumbnailUrl;

  /// Cover picked on this device (file path, or blob URL on web).
  final String? coverLocalPath;

  /// People who have posted at least once.
  final int contributorCount;

  /// People who joined (including those who have not posted yet).
  int memberCount;

  final DateTime startAt, endAt;
  final DateTime createdAt;
  final bool fromFollowing;
  final PartyPrivacy privacy;
  final TimerStyle timerStyle;

  /// Host's user id.
  final String? hostId;

  /// Ids of members with access (host, invited and approved people).
  final Set<String> memberIds;

  /// Popularity rank used by "Trending" (mock data until the backend provides one).
  final int trendScore;

  /// Posts, newest first. Only metadata lives here; media is loaded lazily by
  /// the widgets that show it.
  final List<FeedPost> posts;

  FeedParty({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.thumbnailUrl,
    this.coverLocalPath,
    required this.contributorCount,
    int? memberCount,
    required this.startAt,
    required this.endAt,
    DateTime? createdAt,
    required this.posts,
    this.fromFollowing = false,
    this.privacy = PartyPrivacy.public,
    this.timerStyle = TimerStyle.digital,
    this.hostId,
    Set<String>? memberIds,
    this.trendScore = 0,
  })  : memberCount = memberCount ?? contributorCount,
        createdAt = createdAt ?? startAt,
        memberIds = memberIds ?? {};

  String get shareUrl => 'https://picparty.app/p/$id';

  Duration get duration => endAt.difference(startAt);

  bool isHostedBy(String userId) => hostId == userId;

  bool hasMember(String userId) => hostId == userId || memberIds.contains(userId);
}
