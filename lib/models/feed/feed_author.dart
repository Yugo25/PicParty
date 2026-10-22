/// A person shown in the app: post authors, people in search, chat partners.
class FeedAuthor {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  const FeedAuthor({required this.id, required this.username, this.displayName, this.avatarUrl});

  String get handle => '@$username';

  /// Display name, falling back to the username.
  String get name => displayName?.trim().isNotEmpty == true ? displayName! : username;

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();
}
