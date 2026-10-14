/// A person who posted into a Party (feed view model).
class FeedAuthor {
  final String id;
  final String username;
  final String? avatarUrl;

  const FeedAuthor({required this.id, required this.username, this.avatarUrl});

  String get handle => '@$username';
  String get initial => username.isEmpty ? '?' : username[0].toUpperCase();
}
