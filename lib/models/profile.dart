class Profile {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String preferredLanguage;
  final String preferredTimezone;
  final bool onboardingCompleted;

  const Profile({required this.id, required this.username, this.displayName, this.avatarUrl, this.bio, this.preferredLanguage = 'en', this.preferredTimezone = 'UTC', this.onboardingCompleted = false});

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
    id: m['id'] as String,
    username: m['username'] as String,
    displayName: m['display_name'] as String?,
    avatarUrl: m['avatar_url'] as String?,
    bio: m['bio'] as String?,
    preferredLanguage: (m['preferred_language'] as String?) ?? 'en',
    preferredTimezone: (m['preferred_timezone'] as String?) ?? 'UTC',
    onboardingCompleted: (m['onboarding_completed'] as bool?) ?? false,
  );

  String get name => displayName?.trim().isNotEmpty == true ? displayName! : username;
}
