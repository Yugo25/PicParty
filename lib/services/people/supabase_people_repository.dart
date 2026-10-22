import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../models/feed/feed_author.dart';
import '../../repositories/profile_repository.dart';
import 'people_repository.dart';

/// Real profiles and follows from Supabase.
class SupabasePeopleRepository extends PeopleRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  /// People seen on profile pages, for [userById].
  final _known = <String, FeedAuthor>{};

  /// Ids the current user follows. Null until loaded.
  Set<String>? _following;
  Future<void>? _loadingFollowing;

  @override
  String get currentUserId => _client.auth.currentUser?.id ?? '';

  @override
  Future<UserProfile> currentProfile() async {
    final p = await profile(currentUserId);
    if (p == null) throw StateError('Your profile could not be loaded');
    return p;
  }

  @override
  Future<UserProfile?> profile(String userId) async {
    final following = _loadFollowing();
    final row = await _client.rpc('get_profile_card', params: {'p_user': userId});
    await following;
    if (row == null) return null;
    final m = Map<String, dynamic>.from(row as Map);
    final user = FeedAuthor(
      id: m['id'] as String,
      username: m['username'] as String,
      displayName: m['display_name'] as String?,
      avatarUrl: m['avatar_url'] as String?,
    );
    _known[user.id] = user;
    return UserProfile(
      user: user,
      bio: m['bio'] as String?,
      followers: (m['followers'] as num).toInt(),
      following: (m['following'] as num).toInt(),
    );
  }

  /// Loads who the current user follows once, then tells Follow buttons.
  Future<void> _loadFollowing() {
    if (_following != null) return Future.value();
    return _loadingFollowing ??= () async {
      try {
        final ids = await _client.rpc('get_my_following') as List;
        _following = {for (final id in ids) id as String};
        notifyListeners();
      } finally {
        _loadingFollowing = null;
      }
    }();
  }

  @override
  FeedAuthor? userById(String userId) => _known[userId];

  @override
  bool isFollowing(String userId) => _following?.contains(userId) ?? false;

  @override
  Future<void> setFollowing(String userId, bool follow) async {
    // Optimistic: update now, roll back if the request fails.
    final following = _following ??= {};
    follow ? following.add(userId) : following.remove(userId);
    notifyListeners();
    try {
      await _client.rpc(follow ? 'follow_user' : 'unfollow_user', params: {'pid': userId});
      // Profile pages reload their follower counts.
      notifyListeners();
    } catch (_) {
      follow ? following.remove(userId) : following.add(userId);
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> updateProfile({required String displayName, required String username, required String bio}) async {
    final current = await ProfileRepository().current();
    await ProfileRepository().update(
      username: username,
      displayName: displayName,
      bio: bio,
      language: current?.preferredLanguage ?? 'en',
      timezone: current?.preferredTimezone ?? 'UTC',
    );
    notifyListeners();
  }

  @override
  void resetCurrentUser() {
    _following = null;
    _known.clear();
    notifyListeners();
  }
}
