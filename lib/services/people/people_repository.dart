import 'package:flutter/foundation.dart';
import '../../models/feed/feed_author.dart';
import 'mock_people_repository.dart';

/// A profile page's header data.
@immutable
class UserProfile {
  final FeedAuthor user;
  final String? bio;
  final int followers, following;

  const UserProfile({required this.user, this.bio, required this.followers, required this.following});
}

/// People, profiles and follows. Notifies when follows or the current
/// profile change.
abstract class PeopleRepository extends ChangeNotifier {
  /// The repository the app uses. Swap for an API-backed one later.
  static PeopleRepository instance = MockPeopleRepository();

  String get currentUserId;

  Future<UserProfile> currentProfile();

  /// Null when the person does not exist (or is not visible).
  Future<UserProfile?> profile(String userId);

  /// Synchronous lookup for list rows that already have an id.
  FeedAuthor? userById(String userId);

  bool isFollowing(String userId);

  Future<void> setFollowing(String userId, bool follow);

  Future<void> updateProfile({required String displayName, required String username, required String bio});

  /// Forgets the signed-in profile after signing out or switching accounts.
  void resetCurrentUser();
}
