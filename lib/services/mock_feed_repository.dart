import 'package:flutter/foundation.dart';
import '../models/comment.dart';
import '../models/feed/feed_author.dart';
import '../models/feed/feed_party.dart';
import '../models/feed/feed_post.dart';

enum FeedTab { forYou, following }

/// In-memory stand-in for the feed backend.
///
/// Photos come from picsum.photos (Unsplash images) requested at the size they
/// are displayed at. Times are relative to app start so every state — upcoming,
/// live (minutes / hours / days left) and closed — is always visible.
class MockFeedRepository extends ChangeNotifier {
  MockFeedRepository._();
  static final instance = MockFeedRepository._();

  static const _videoButterfly = 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';
  static const _videoBee = 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

  late final List<FeedParty> _parties = _seed(DateTime.now());
  final Map<String, List<Comment>> _comments = {};

  /// Returns one page of Parties. Simulates network latency.
  Future<List<FeedParty>> fetchParties({required FeedTab tab, required int page, required int pageSize}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final source = tab == FeedTab.following ? _parties.where((p) => p.fromFollowing).toList() : _parties;
    return source.skip(page * pageSize).take(pageSize).toList();
  }

  FeedParty? party(String id) {
    for (final p in _parties) {
      if (p.id == id) return p;
    }
    return null;
  }

  void toggleLike(FeedPost post) {
    final r = post.reactions.value;
    post.reactions.value = r.copyWith(liked: !r.liked, likeCount: r.likeCount + (r.liked ? -1 : 1));
  }

  List<Comment> comments(FeedPost post) => _comments.putIfAbsent(post.id, () => _seedComments(post));

  void addComment(FeedPost post, String text) {
    final now = DateTime.now().toUtc();
    comments(post).add(Comment(
        id: 'c-${post.id}-${now.microsecondsSinceEpoch}',
        mediaId: post.id,
        userId: 'demo-user',
        content: text,
        username: 'you',
        createdAt: now,
        updatedAt: now));
    final r = post.reactions.value;
    post.reactions.value = r.copyWith(commentCount: r.commentCount + 1);
  }

  /// Adds a photo picked on this device to a live Party (demo only — stays in memory).
  void addLocalPost(FeedParty party, {required String path, required bool video}) {
    party.posts.insert(
        0,
        FeedPost(
          id: '${party.id}-local-${DateTime.now().microsecondsSinceEpoch}',
          partyId: party.id,
          author: const FeedAuthor(id: 'demo-user', username: 'you'),
          type: video ? FeedMediaType.video : FeedMediaType.photo,
          localPath: path,
          createdAt: DateTime.now().toUtc(),
          reactions: const PostReactions(likeCount: 0, commentCount: 0),
        ));
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Seed data

  static SizedImageUrl _picsum(int id) => (w, h) => 'https://picsum.photos/id/$id/$w/$h';

  static const _authors = [
    FeedAuthor(id: 'u1', username: 'sarah.k', avatarUrl: 'https://picsum.photos/id/64/96/96'),
    FeedAuthor(id: 'u2', username: 'kenjiro', avatarUrl: 'https://picsum.photos/id/91/96/96'),
    FeedAuthor(id: 'u3', username: 'mina.lee', avatarUrl: 'https://picsum.photos/id/65/96/96'),
    FeedAuthor(id: 'u4', username: 'theo', avatarUrl: 'https://picsum.photos/id/338/96/96'),
    FeedAuthor(id: 'u5', username: 'aiko_t', avatarUrl: 'https://picsum.photos/id/1027/96/96'),
    FeedAuthor(id: 'u6', username: 'daniel.r', avatarUrl: 'https://picsum.photos/id/1005/96/96'),
    FeedAuthor(id: 'u7', username: 'lena'),
    FeedAuthor(id: 'u8', username: 'yuto.m'),
  ];

  static const _captions = [
    'A quiet morning in Kyoto.',
    'An afternoon well spent.',
    'Found this on the way home.',
    'The light was perfect for a minute.',
    'Worth the early start.',
    'Couldn\'t stop looking at this.',
    'Small things, good day.',
    'Same place, different hour.',
  ];

  static List<FeedParty> _seed(DateTime now) {
    FeedParty party({
      required String id,
      required String title,
      required int contributors,
      required DateTime start,
      required DateTime end,
      required List<int> photoIds,
      Map<int, String> videos = const {},
      List<String>? captions,
      bool following = false,
      int authorOffset = 0,
    }) {
      final posts = <FeedPost>[
        for (var i = 0; i < photoIds.length; i++)
          FeedPost(
            id: '$id-$i',
            partyId: id,
            author: _authors[(i + authorOffset) % _authors.length],
            type: videos.containsKey(i) ? FeedMediaType.video : FeedMediaType.photo,
            imageUrl: _picsum(photoIds[i]),
            videoUrl: videos[i],
            caption: captions != null ? captions[i % captions.length] : _captions[(i + authorOffset) % _captions.length],
            createdAt: now.subtract(Duration(minutes: 7 * i + 3)),
            reactions: PostReactions(likeCount: 124 - (i * 37 + authorOffset * 11) % 110, commentCount: 12 - (i * 7) % 11),
          ),
      ];
      return FeedParty(
        id: id,
        title: title,
        thumbnailUrl: _picsum(photoIds.first),
        contributorCount: contributors,
        startAt: start,
        endAt: end,
        posts: posts,
        fromFollowing: following,
      );
    }

    final kyotoIds = [1040, 1047, 1036, 1039, 1043, 1044, 1048, 1049, 1050, 1051, 1053, 1054, 1055, 1056, 1057, 1058, 1059, 1061, 1063, 1064, 1065, 1066, 1067, 1068];

    return [
      party(
        id: 'kyoto',
        title: 'Kyoto through our eyes',
        contributors: 128,
        start: now.subtract(const Duration(hours: 17)),
        end: now.add(const Duration(hours: 6, minutes: 24, seconds: 18)),
        photoIds: kyotoIds,
        captions: ['A quiet morning in Kyoto.', 'An afternoon well spent.', 'Lanterns before dusk.', 'Moss, stone, rain.'],
      ),
      party(
        id: 'food',
        title: 'Weekend food finds',
        contributors: 64,
        start: now.subtract(const Duration(hours: 22)),
        end: now.add(const Duration(hours: 1, minutes: 12, seconds: 5)),
        photoIds: [292, 1080, 102, 225, 431, 488],
        videos: {2: _videoBee},
        captions: ['Ramen worth the queue.', 'Market strawberries.', 'Busy little helpers at the farm.', 'Tea, slowly.', 'Breakfast for two.', 'Last bite.'],
        following: true,
        authorOffset: 2,
      ),
      party(
        id: 'coffee',
        title: 'Coffee break',
        contributors: 19,
        start: now.subtract(const Duration(hours: 2)),
        end: now.add(const Duration(minutes: 2, seconds: 30)),
        photoIds: [1060, 30, 63, 42, 766],
        captions: ['Closing soon — last cups.', 'Oat flat white.', 'Morning ritual.', 'Corner table.', 'Refill?'],
        authorOffset: 4,
      ),
      party(
        id: 'coast',
        title: 'Last light at the coast',
        contributors: 212,
        start: now.subtract(const Duration(hours: 5)),
        end: now.add(const Duration(days: 2, hours: 6, minutes: 24)),
        photoIds: [1015, 1016, 1018, 1019, 1022, 1035, 1069, 100],
        videos: {3: _videoButterfly},
        following: true,
        authorOffset: 1,
      ),
      party(
        id: 'night',
        title: 'Night city lights',
        contributors: 1,
        start: now.add(const Duration(hours: 3, minutes: 10)),
        end: now.add(const Duration(hours: 27, minutes: 10)),
        photoIds: [1067],
        captions: ['Cover photo from the host — uploads open soon.'],
        authorOffset: 5,
      ),
      party(
        id: 'autumn',
        title: 'Autumn walks',
        contributors: 87,
        start: now.subtract(const Duration(days: 2, hours: 4)),
        end: now.subtract(const Duration(hours: 20)),
        photoIds: [1020, 1021, 1025, 1074, 167, 174, 177],
        following: true,
        authorOffset: 3,
      ),
      party(
        id: 'pets',
        title: 'Pets at home',
        contributors: 45,
        start: now.subtract(const Duration(hours: 3)),
        end: now.add(const Duration(hours: 4, minutes: 41)),
        photoIds: [237, 1062, 40, 169, 433, 593],
        authorOffset: 6,
      ),
      party(
        id: 'street',
        title: 'Street snaps',
        contributors: 156,
        start: now.subtract(const Duration(hours: 9)),
        end: now.add(const Duration(hours: 9, minutes: 3)),
        photoIds: [1076, 1077, 1078, 1079, 1081, 1082, 1083, 1084],
        authorOffset: 7,
      ),
    ];
  }

  static List<Comment> _seedComments(FeedPost post) {
    final n = post.reactions.value.commentCount;
    const lines = ['Beautiful light.', 'Where is this?', 'Love this one.', 'Saving this.', 'So calm.', 'Great shot!'];
    final now = DateTime.now().toUtc();
    return [
      for (var i = 0; i < n; i++)
        Comment(
          id: 'c-${post.id}-seed-$i',
          mediaId: post.id,
          userId: _authors[(i + 3) % _authors.length].id,
          content: lines[i % lines.length],
          username: _authors[(i + 3) % _authors.length].username,
          avatarUrl: _authors[(i + 3) % _authors.length].avatarUrl,
          createdAt: now.subtract(Duration(minutes: 5 * (n - i))),
          updatedAt: now,
        ),
    ];
  }
}
