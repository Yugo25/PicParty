import '../../config/app_config.dart';
import '../../models/feed/feed_author.dart';
import '../../repositories/profile_repository.dart';
import '../mock/mock_network.dart';
import '../mock/mock_people.dart';
import 'people_repository.dart';

/// Demo people and follows, kept in memory for this session.
///
/// The signed-in profile still comes from [ProfileRepository] (its demo
/// profile in demo mode, the real one otherwise); only follows and other
/// people are mocked.
class MockPeopleRepository extends PeopleRepository {
  final _following = <String>{'u1', 'u2'};
  static const _followersOfMe = {'u4', 'u6', 'u8'};

  UserProfile? _me;

  @override
  String get currentUserId => _me?.user.id ?? MockPeople.meId;

  @override
  Future<UserProfile> currentProfile() async {
    await MockNetwork.request(const Duration(milliseconds: 200));
    if (_me != null) return _withCounts(_me!);
    final p = await ProfileRepository().current();
    _me = UserProfile(
      user: p == null
          ? MockPeople.me
          : FeedAuthor(id: p.id, username: p.username, displayName: p.displayName, avatarUrl: p.avatarUrl),
      bio: p?.bio,
      followers: 0,
      following: 0,
    );
    return _withCounts(_me!);
  }

  UserProfile _withCounts(UserProfile p) =>
      UserProfile(user: p.user, bio: p.bio, followers: _followersOfMe.length, following: _following.length);

  @override
  Future<UserProfile?> profile(String userId) async {
    if (userId == currentUserId) return currentProfile();
    await MockNetwork.request(const Duration(milliseconds: 200));
    final user = MockPeople.byId(userId);
    if (user == null) return null;
    // Stable made-up counts per person, plus the viewer's own follow.
    final seed = userId.codeUnits.fold<int>(7, (a, c) => a * 31 + c) % 400;
    return UserProfile(
      user: user,
      bio: MockPeople.bios[userId],
      followers: 40 + seed + (_following.contains(userId) ? 1 : 0),
      following: 20 + seed ~/ 3,
    );
  }

  @override
  FeedAuthor? userById(String userId) => userId == currentUserId ? (_me?.user ?? MockPeople.me) : MockPeople.byId(userId);

  @override
  bool isFollowing(String userId) => _following.contains(userId);

  @override
  Future<void> setFollowing(String userId, bool follow) async {
    // Optimistic: update now, roll back if the (mock) request fails.
    final before = _following.contains(userId);
    follow ? _following.add(userId) : _following.remove(userId);
    notifyListeners();
    try {
      await MockNetwork.request(const Duration(milliseconds: 150));
    } catch (_) {
      before ? _following.add(userId) : _following.remove(userId);
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> updateProfile({required String displayName, required String username, required String bio}) async {
    if (!AppConfig.demoMode) {
      final current = await ProfileRepository().current();
      await ProfileRepository().update(
        username: username,
        displayName: displayName,
        bio: bio,
        language: current?.preferredLanguage ?? 'en',
        timezone: current?.preferredTimezone ?? 'UTC',
      );
    } else {
      await MockNetwork.request();
    }
    final me = await currentProfile();
    _me = UserProfile(
      user: FeedAuthor(id: me.user.id, username: username, displayName: displayName, avatarUrl: me.user.avatarUrl),
      bio: bio,
      followers: me.followers,
      following: me.following,
    );
    notifyListeners();
  }

  @override
  void resetCurrentUser() {
    _me = null;
    notifyListeners();
  }
}
