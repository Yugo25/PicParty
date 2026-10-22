import 'package:image_picker/image_picker.dart';
import '../models/comment.dart';
import '../models/feed/feed_author.dart';
import '../models/feed/feed_party.dart';
import '../models/feed/feed_post.dart';
import '../models/feed/party_options.dart';
import '../repositories/party_repository.dart';
import 'feed/feed_repository.dart';
import 'mock/mock_network.dart';
import 'mock/mock_people.dart';

export 'feed/feed_repository.dart' show FeedTab;

/// In-memory stand-in for the Party / post backend (demo data only).
///
/// Photos come from picsum.photos (Unsplash images) requested at the size they
/// are displayed at. Times are relative to app start so every state — upcoming,
/// live (minutes / hours / days left) and closed — is always visible.
class MockFeedRepository extends FeedRepository {
  MockFeedRepository._();
  static final instance = MockFeedRepository._();

  static const _videoButterfly = 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';
  static const _videoBee = 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

  late final List<FeedParty> _parties = _seed(DateTime.now());
  final Map<String, List<Comment>> _comments = {};

  /// Every Party, including ones the current user cannot open. Callers filter.
  List<FeedParty> get all => List.unmodifiable(_parties);

  /// Returns one page of the home feed. Simulates network latency.
  ///
  /// Only Parties that are public, or that the user hosts / is a member of,
  /// appear here — unlisted and private Parties are never "discovered".
  @override
  Future<List<FeedParty>> fetchParties({required FeedTab tab, required int page, required int pageSize}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final source = _parties.where((p) => p.posts.isNotEmpty || p.thumbnailUrl != null || p.coverLocalPath != null).where((p) {
      if (tab == FeedTab.following && !p.fromFollowing) return false;
      return p.privacy == PartyPrivacy.public || p.hasMember(MockPeople.meId);
    }).toList();
    return source.skip(page * pageSize).take(pageSize).toList();
  }

  @override
  FeedParty? party(String id) {
    for (final p in _parties) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<FeedParty?> loadParty(String id) async => party(id);

  /// Public and unlisted Parties open for anyone with the link; private ones
  /// only for the host and members.
  @override
  bool canView(FeedParty party, {String userId = MockPeople.meId}) =>
      party.privacy != PartyPrivacy.private || party.hasMember(userId);

  /// Others only see what the viewer is allowed to open.
  @override
  Future<ProfileParties> partiesOf(String userId) async {
    bool visible(FeedParty x) => userId == MockPeople.meId || x.privacy == PartyPrivacy.public || canView(x);
    return ProfileParties(
      hosted: hostedBy(userId).where(visible).toList(),
      joined: joinedBy(userId).where(visible).toList(),
      posts: [
        for (final post in postsBy(userId))
          if (party(post.partyId) case final p? when visible(p)) post,
      ],
    );
  }

  /// Adds the current user as a member (accepted invite).
  void join(String partyId) {
    final p = party(partyId);
    if (p == null || p.hasMember(MockPeople.meId)) return;
    p.memberIds.add(MockPeople.meId);
    p.memberCount++;
    notifyListeners();
  }

  /// A Party just created on this device.
  void addParty(FeedParty party) {
    _parties.insert(0, party);
    notifyListeners();
  }

  List<FeedParty> hostedBy(String userId) => _parties.where((p) => p.isHostedBy(userId)).toList();

  List<FeedParty> joinedBy(String userId) => _parties.where((p) => !p.isHostedBy(userId) && p.memberIds.contains(userId)).toList();

  /// Posts by [userId] across all Parties, newest first.
  List<FeedPost> postsBy(String userId) =>
      [for (final p in _parties) ...p.posts.where((post) => post.author.id == userId)]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> toggleLike(FeedPost post) async {
    final r = post.reactions.value;
    post.reactions.value = r.copyWith(liked: !r.liked, likeCount: r.likeCount + (r.liked ? -1 : 1));
  }

  List<Comment> _commentsOf(FeedPost post) => _comments.putIfAbsent(post.id, () => _seedComments(post));

  @override
  Future<List<Comment>> comments(FeedPost post) async => List.of(_commentsOf(post));

  @override
  Future<void> addComment(FeedPost post, String text) async {
    final now = DateTime.now().toUtc();
    _commentsOf(post).add(Comment(
        id: 'c-${post.id}-${now.microsecondsSinceEpoch}',
        mediaId: post.id,
        userId: MockPeople.meId,
        content: text,
        username: MockPeople.me.username,
        createdAt: now,
        updatedAt: now));
    final r = post.reactions.value;
    post.reactions.value = r.copyWith(commentCount: r.commentCount + 1);
  }

  @override
  Future<void> addPhoto(FeedParty party, XFile file) async => addLocalPost(party, path: file.path, video: false);

  @override
  Future<FeedParty> createParty({
    required String title,
    String? description,
    String? category,
    required PartyPrivacy privacy,
    required TimerStyle timerStyle,
    required DateTime startAt,
    required Duration duration,
    XFile? cover,
  }) async {
    await MockNetwork.request(const Duration(milliseconds: 600));
    final created = await PartyRepository().create(
      title: title,
      description: description,
      category: category,
      language: 'en',
      style: timerStyle.name,
      privacy: privacy.name,
      startAt: startAt,
      durationMinutes: duration.inMinutes,
    );
    final party = FeedParty(
      id: created.id,
      title: created.title,
      description: created.description,
      category: created.category,
      coverLocalPath: cover?.path,
      contributorCount: 0,
      memberCount: 1,
      startAt: created.startAt,
      endAt: created.endAt,
      createdAt: created.createdAt,
      posts: [],
      privacy: privacy,
      timerStyle: timerStyle,
      hostId: MockPeople.meId,
      memberIds: {MockPeople.meId},
    );
    addParty(party);
    return party;
  }

  /// Adds a photo picked on this device to a live Party (demo only — stays in memory).
  void addLocalPost(FeedParty party, {required String path, required bool video}) {
    party.posts.insert(
        0,
        FeedPost(
          id: '${party.id}-local-${DateTime.now().microsecondsSinceEpoch}',
          partyId: party.id,
          author: MockPeople.me,
          type: video ? FeedMediaType.video : FeedMediaType.photo,
          localPath: path,
          createdAt: DateTime.now().toUtc(),
          reactions: const PostReactions(likeCount: 0, commentCount: 0),
        ));
    party.memberIds.add(MockPeople.meId);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Seed data

  static SizedImageUrl _picsum(int id) => (w, h) => 'https://picsum.photos/id/$id/$w/$h';

  static const _authors = MockPeople.others;

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
    const me = MockPeople.meId;
    FeedParty party({
      required String id,
      required String title,
      required String category,
      required String host,
      required int contributors,
      int? members,
      required DateTime start,
      required DateTime end,
      required List<int> photoIds,
      int? coverId,
      Map<int, String> videos = const {},
      Set<int> postedByMe = const {},
      List<String>? captions,
      bool following = false,
      bool joined = false,
      PartyPrivacy privacy = PartyPrivacy.public,
      int trend = 0,
      String? description,
      int authorOffset = 0,
    }) {
      final posts = <FeedPost>[
        for (var i = 0; i < photoIds.length; i++)
          FeedPost(
            id: '$id-$i',
            partyId: id,
            author: postedByMe.contains(i) ? MockPeople.me : _authors[(i + authorOffset) % _authors.length],
            type: videos.containsKey(i) ? FeedMediaType.video : FeedMediaType.photo,
            imageUrl: _picsum(photoIds[i]),
            videoUrl: videos[i],
            caption: captions != null ? captions[i % captions.length] : _captions[(i + authorOffset) % _captions.length],
            createdAt: (end.isBefore(now) ? end : now).subtract(Duration(minutes: 7 * i + 3)),
            reactions: PostReactions(likeCount: 124 - (i * 37 + authorOffset * 11) % 110, commentCount: 12 - (i * 7) % 11),
          ),
      ];
      return FeedParty(
        id: id,
        title: title,
        description: description,
        category: category,
        thumbnailUrl: _picsum(coverId ?? photoIds.first),
        contributorCount: contributors,
        memberCount: members ?? contributors,
        startAt: start,
        endAt: end,
        createdAt: start.subtract(const Duration(hours: 2)),
        posts: posts,
        fromFollowing: following,
        privacy: privacy,
        hostId: host,
        memberIds: {host, if (joined || postedByMe.isNotEmpty) me},
        trendScore: trend,
      );
    }

    final kyotoIds = [1040, 1047, 1036, 1039, 1043, 1044, 1048, 1049, 1050, 1051, 1053, 1054, 1055, 1056, 1057, 1058, 1059, 1061, 1063, 1064, 1065, 1066, 1067, 1068];

    return [
      party(
        id: 'kyoto',
        title: 'Kyoto through our eyes',
        category: 'travel',
        host: 'u5',
        contributors: 128,
        start: now.subtract(const Duration(hours: 17)),
        end: now.add(const Duration(hours: 6, minutes: 24, seconds: 18)),
        photoIds: kyotoIds,
        postedByMe: {2},
        trend: 92,
        captions: ['A quiet morning in Kyoto.', 'An afternoon well spent.', 'Lanterns before dusk.', 'Moss, stone, rain.'],
        description: 'Temples, side streets and small moments around Kyoto.',
        authorOffset: 4,
      ),
      party(
        id: 'food',
        title: 'Weekend food finds',
        category: 'food',
        host: 'u2',
        contributors: 64,
        start: now.subtract(const Duration(hours: 22)),
        end: now.add(const Duration(hours: 1, minutes: 12, seconds: 5)),
        photoIds: [292, 1080, 102, 225, 431, 488],
        videos: {2: _videoBee},
        trend: 75,
        captions: ['Ramen worth the queue.', 'Market strawberries.', 'Busy little helpers at the farm.', 'Tea, slowly.', 'Breakfast for two.', 'Last bite.'],
        following: true,
        authorOffset: 2,
      ),
      party(
        id: 'coffee',
        title: 'Coffee break',
        category: 'food',
        host: 'u7',
        contributors: 19,
        start: now.subtract(const Duration(hours: 2)),
        end: now.add(const Duration(minutes: 2, seconds: 30)),
        photoIds: [1060, 30, 63, 42, 766],
        postedByMe: {1},
        trend: 40,
        captions: ['Closing soon — last cups.', 'Oat flat white.', 'Morning ritual.', 'Corner table.', 'Refill?'],
        authorOffset: 4,
      ),
      party(
        id: 'coast',
        title: 'Last light at the coast',
        category: 'nature',
        host: 'u6',
        contributors: 212,
        start: now.subtract(const Duration(hours: 5)),
        end: now.add(const Duration(days: 2, hours: 6, minutes: 24)),
        photoIds: [1015, 1016, 1018, 1019, 1022, 1035, 1069, 100],
        videos: {3: _videoButterfly},
        postedByMe: {1},
        trend: 88,
        following: true,
        authorOffset: 1,
      ),
      party(
        id: 'night',
        title: 'Night city lights',
        category: 'photography',
        host: me,
        contributors: 0,
        members: 42,
        start: now.add(const Duration(hours: 3, minutes: 10)),
        end: now.add(const Duration(hours: 27, minutes: 10)),
        photoIds: const [],
        coverId: 1067,
        trend: 30,
        description: 'Neon, rain and late trains. Uploads open at sunset.',
      ),
      party(
        id: 'autumn',
        title: 'Autumn walks',
        category: 'nature',
        host: 'u3',
        contributors: 87,
        start: now.subtract(const Duration(days: 2, hours: 4)),
        end: now.subtract(const Duration(hours: 20)),
        photoIds: [1020, 1021, 1025, 1074, 167, 174, 177],
        postedByMe: {1},
        trend: 60,
        following: true,
        authorOffset: 3,
      ),
      party(
        id: 'pets',
        title: 'Pets at home',
        category: 'pets',
        host: me,
        contributors: 45,
        start: now.subtract(const Duration(hours: 3)),
        end: now.add(const Duration(hours: 4, minutes: 41)),
        photoIds: [237, 1062, 40, 169, 433, 593],
        trend: 55,
        authorOffset: 6,
      ),
      party(
        id: 'street',
        title: 'Street snaps',
        category: 'photography',
        host: 'u1',
        contributors: 156,
        start: now.subtract(const Duration(hours: 9)),
        end: now.add(const Duration(hours: 9, minutes: 3)),
        photoIds: [1076, 1077, 1078, 1079, 1081, 1082, 1083, 1084],
        trend: 80,
        authorOffset: 7,
      ),
      party(
        id: 'montreal',
        title: 'Montreal after hours',
        category: 'travel',
        host: 'u3',
        contributors: 0,
        members: 12,
        start: now.add(const Duration(hours: 2)),
        end: now.add(const Duration(hours: 8)),
        photoIds: const [],
        coverId: 1031,
        privacy: PartyPrivacy.private,
        trend: 45,
        description: 'Share the city\'s little moments after sunset.',
      ),
      party(
        id: 'music',
        title: 'Music in the park',
        category: 'music',
        host: 'u4',
        contributors: 73,
        start: now.subtract(const Duration(hours: 6)),
        end: now.add(const Duration(days: 1, hours: 6, minutes: 12)),
        photoIds: [452, 454, 158, 145, 96],
        trend: 70,
        authorOffset: 3,
      ),
      party(
        id: 'city',
        title: 'City in film',
        category: 'photography',
        host: 'u10',
        contributors: 31,
        start: now.subtract(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 3, minutes: 21, seconds: 17)),
        photoIds: [1041, 1042, 1045, 1052],
        joined: true,
        trend: 50,
        authorOffset: 5,
      ),
      party(
        id: 'trails',
        title: 'Weekend trails',
        category: 'nature',
        host: 'u4',
        contributors: 58,
        start: now.subtract(const Duration(hours: 18)),
        end: now.add(const Duration(days: 1, hours: 6, minutes: 2)),
        photoIds: [1070, 1071, 1072, 1073, 1075],
        trend: 65,
        authorOffset: 2,
      ),
      party(
        id: 'studio',
        title: 'Studio friends',
        category: 'art',
        host: 'u9',
        contributors: 8,
        start: now.subtract(const Duration(hours: 4)),
        end: now.add(const Duration(hours: 20)),
        photoIds: [119, 129, 139],
        privacy: PartyPrivacy.unlisted,
        trend: 20,
        authorOffset: 8,
      ),
      party(
        id: 'banff',
        title: 'Weekend in Banff',
        category: 'nature',
        host: 'u4',
        contributors: 61,
        start: now.subtract(const Duration(days: 124)),
        end: now.subtract(const Duration(days: 122)),
        photoIds: [1011, 1012, 1013, 1014, 1023, 1024, 1026, 1028, 1029, 1032, 1033, 1037],
        postedByMe: {0, 4},
        trend: 10,
      ),
      party(
        id: 'summer',
        title: 'Summer memories',
        category: 'travel',
        host: me,
        contributors: 94,
        start: now.subtract(const Duration(days: 164)),
        end: now.subtract(const Duration(days: 163)),
        photoIds: [1000, 1001, 1002, 1003, 1004, 1006, 1008, 1009, 1010],
        postedByMe: {2},
        trend: 12,
        authorOffset: 1,
      ),
    ];
  }

  static List<Comment> _seedComments(FeedPost post) {
    final n = post.reactions.value.commentCount;
    const lines = ['Beautiful light.', 'Where is this?', 'Love this one.', 'Saving this.', 'So calm.', 'Great shot!'];
    final now = DateTime.now().toUtc();
    FeedAuthor who(int i) => _authors[(i + 3) % _authors.length];
    return [
      for (var i = 0; i < n; i++)
        Comment(
          id: 'c-${post.id}-seed-$i',
          mediaId: post.id,
          userId: who(i).id,
          content: lines[i % lines.length],
          username: who(i).username,
          avatarUrl: who(i).avatarUrl,
          createdAt: now.subtract(Duration(minutes: 5 * (n - i))),
          updatedAt: now,
        ),
    ];
  }
}
