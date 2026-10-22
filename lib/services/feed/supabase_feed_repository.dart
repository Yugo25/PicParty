import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../config/supabase_config.dart';
import '../../models/comment.dart';
import '../../models/feed/feed_author.dart';
import '../../models/feed/feed_party.dart';
import '../../models/feed/feed_post.dart';
import '../../models/feed/party_options.dart';
import '../../repositories/party_repository.dart';
import 'feed_repository.dart';

/// Parties, posts, likes and comments stored in Supabase, shared by everyone.
///
/// Lists come from the database functions in
/// `supabase/migrations/116_sharing.sql`, which only return what the signed-in
/// person may see. Photos live in the private `party-media` bucket and are
/// shown through signed URLs.
class SupabaseFeedRepository extends FeedRepository {
  SupabaseClient get _client => SupabaseConfig.client;
  String get _me => _client.auth.currentUser!.id;

  static const _bucket = 'party-media';
  static const _urlLifetime = Duration(hours: 6);
  static final _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);

  /// Every Party loaded so far, so [party] can answer without waiting.
  final _parties = <String, FeedParty>{};

  /// Private Parties the current user can't open.
  final _locked = <String>{};

  /// Signed photo URLs by storage path, reused until they are close to
  /// expiring so images aren't downloaded again on every refresh.
  final _urls = <String, ({String url, DateTime expires})>{};

  @override
  Future<List<FeedParty>> fetchParties({required FeedTab tab, required int page, required int pageSize}) => queryParties(
        view: tab == FeedTab.forYou ? 'for_you' : 'following',
        limit: pageSize,
        offset: page * pageSize,
      );

  /// One page of `get_parties`. Explore uses this for its views and search.
  Future<List<FeedParty>> queryParties({required String view, String? userId, String text = '', String? category, int limit = 20, int offset = 0}) async {
    final rows = await _client.rpc('get_parties', params: {
      'p_view': view,
      'p_user': userId,
      'p_text': text,
      'p_category': category,
      'p_limit': limit,
      'p_offset': offset,
    }) as List;
    final parties = await _toParties([for (final r in rows) Map<String, dynamic>.from(r as Map)]);
    for (final p in parties) {
      _parties[p.id] = p;
    }
    return parties;
  }

  @override
  FeedParty? party(String id) => _parties[id];

  @override
  Future<FeedParty?> loadParty(String id) async {
    // Old demo links (/p/kyoto) aren't real ids.
    if (!_uuid.hasMatch(id)) return null;
    final row = await _client.rpc('get_party', params: {'pid': id});
    FeedParty? party;
    if (row == null) {
      _parties.remove(id);
    } else if (row['locked'] == true) {
      _locked.add(id);
      final now = DateTime.now().toUtc();
      party = _parties[id] = FeedParty(id: id, title: '', contributorCount: 0, startAt: now, endAt: now, posts: [], privacy: PartyPrivacy.private);
    } else {
      _locked.remove(id);
      party = _parties[id] = (await _toParties([Map<String, dynamic>.from(row as Map)])).single;
    }
    notifyListeners();
    return party;
  }

  @override
  bool canView(FeedParty party) => !_locked.contains(party.id);

  @override
  Future<ProfileParties> partiesOf(String userId) async {
    final hosted = queryParties(view: 'hosted', userId: userId, limit: 50);
    final joined = queryParties(view: 'joined', userId: userId, limit: 50);
    final rows = [
      for (final r in await _client.rpc('get_user_posts', params: {'p_user': userId}) as List) Map<String, dynamic>.from(r as Map),
    ];
    final partyRows = [for (final r in rows) Map<String, dynamic>.from(r['party'] as Map)];
    final urls = await _signedUrls([for (final r in rows) r['path'] as String?, for (final p in partyRows) ..._pathsOf(p)]);
    // Keep fuller copies (with all their posts) if they were loaded before.
    for (final p in partyRows) {
      _parties.putIfAbsent(p['id'] as String, () => _party(p, urls));
    }
    return ProfileParties(
      hosted: await hosted,
      joined: await joined,
      posts: [for (final r in rows) _post(r, urls)],
    );
  }

  @override
  Future<void> toggleLike(FeedPost post) async {
    final before = post.reactions.value;
    post.reactions.value = before.copyWith(liked: !before.liked, likeCount: before.likeCount + (before.liked ? -1 : 1));
    try {
      await _client.rpc(before.liked ? 'unlike_media' : 'like_media', params: {'mid': post.id});
    } catch (_) {
      post.reactions.value = before;
    }
  }

  @override
  Future<List<Comment>> comments(FeedPost post) async {
    final rows = await _client.rpc('get_comments', params: {'p_media_id': post.id}) as List;
    return [for (final r in rows) Comment.fromMap(Map<String, dynamic>.from(r as Map))];
  }

  @override
  Future<void> addComment(FeedPost post, String text) async {
    await _client.rpc('create_comment', params: {'p_media_id': post.id, 'p_content': text});
    final r = post.reactions.value;
    post.reactions.value = r.copyWith(commentCount: r.commentCount + 1);
  }

  @override
  Future<void> addPhoto(FeedParty party, XFile file) async {
    if (!party.hasMember(_me)) await _client.rpc('join_party', params: {'pid': party.id});
    final bytes = await file.readAsBytes();
    final id = const Uuid().v4();
    final path = '${party.id}/$_me/$id/original';
    final mime = file.mimeType ?? 'image/jpeg';
    await _client.rpc('create_media_post', params: {
      'p_id': id,
      'p_party_id': party.id,
      'p_media_type': 'image',
      'p_original_storage_path': path,
      'p_file_size': bytes.length,
      'p_mime_type': mime,
    });
    await _client.storage.from(_bucket).uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime));
    await _client.rpc('media_upload_completed', params: {'mid': id});
    await loadParty(party.id);
  }

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
    String? coverPath;
    if (cover != null) {
      // Uploaded before the Party exists, so it goes under covers/{userId}/.
      coverPath = 'covers/$_me/${const Uuid().v4()}';
      await _client.storage.from(_bucket).uploadBinary(coverPath, await cover.readAsBytes(), fileOptions: FileOptions(contentType: cover.mimeType ?? 'image/jpeg'));
    }
    final created = await PartyRepository().create(
      title: title,
      description: description,
      category: category,
      language: 'en',
      style: timerStyle.name,
      privacy: privacy.name,
      startAt: startAt,
      durationMinutes: duration.inMinutes,
      coverStoragePath: coverPath,
    );
    final party = await loadParty(created.id);
    if (party == null) throw StateError('The new Party could not be loaded');
    return party;
  }

  @override
  void clearCache() {
    _parties.clear();
    _locked.clear();
    _urls.clear();
  }

  // ---------------------------------------------------------------------------
  // Rows from the database → app models

  Future<List<FeedParty>> _toParties(List<Map<String, dynamic>> rows) async {
    final urls = await _signedUrls([for (final r in rows) ..._pathsOf(r)]);
    return [for (final r in rows) _party(r, urls)];
  }

  static Iterable<String?> _pathsOf(Map<String, dynamic> party) => [
        party['cover_path'] as String?,
        for (final post in party['posts'] as List? ?? const []) (post as Map)['path'] as String?,
      ];

  Future<Map<String, String>> _signedUrls(Iterable<String?> paths) async {
    final wanted = paths.whereType<String>().toSet();
    final soon = DateTime.now().add(const Duration(hours: 1));
    final missing = [for (final p in wanted) if (!(_urls[p]?.expires.isAfter(soon) ?? false)) p];
    if (missing.isNotEmpty) {
      final expires = DateTime.now().add(_urlLifetime);
      // A missing file just gets no URL; its post shows the placeholder.
      for (final r in await _client.storage.from(_bucket).createSignedUrlsResult(missing, _urlLifetime.inSeconds)) {
        if (r case SignedUrlSuccess(:final path, :final signedUrl)) _urls[path] = (url: signedUrl, expires: expires);
      }
    }
    return {for (final p in wanted) if (_urls[p] case final u?) p: u.url};
  }

  FeedParty _party(Map<String, dynamic> r, Map<String, String> urls) {
    final cover = urls[r['cover_path']];
    return FeedParty(
      id: r['id'] as String,
      title: r['title'] as String,
      description: r['description'] as String?,
      category: r['category'] as String?,
      thumbnailUrl: cover == null ? null : (w, h) => cover,
      contributorCount: (r['contributor_count'] as num).toInt(),
      memberCount: (r['member_count'] as num).toInt(),
      startAt: DateTime.parse(r['start_at'] as String),
      endAt: DateTime.parse(r['end_at'] as String),
      createdAt: DateTime.parse(r['created_at'] as String),
      posts: [for (final p in r['posts'] as List) _post(Map<String, dynamic>.from(p as Map), urls)],
      fromFollowing: r['from_following'] == true,
      privacy: PartyPrivacy.parse(r['privacy'] as String?),
      timerStyle: TimerStyle.parse(r['countdown_style'] as String?),
      hostId: r['owner_id'] as String?,
      memberIds: {if (r['is_member'] == true) _me},
      trendScore: (r['trend'] as num? ?? 0).toInt(),
    );
  }

  FeedPost _post(Map<String, dynamic> r, Map<String, String> urls) {
    final url = urls[r['path']];
    return FeedPost(
      id: r['id'] as String,
      partyId: r['party_id'] as String,
      author: _author(r['author'] as Map?),
      type: FeedMediaType.photo,
      imageUrl: url == null ? null : (w, h) => url,
      caption: r['caption'] as String?,
      createdAt: DateTime.parse(r['created_at'] as String),
      reactions: PostReactions(
        likeCount: (r['like_count'] as num).toInt(),
        commentCount: (r['comment_count'] as num).toInt(),
        liked: r['liked'] == true,
      ),
    );
  }

  static FeedAuthor _author(Map? r) => r == null
      ? const FeedAuthor(id: '', username: 'user')
      : FeedAuthor(
          id: r['id'] as String,
          username: r['username'] as String,
          displayName: r['display_name'] as String?,
          avatarUrl: r['avatar_url'] as String?,
        );
}
