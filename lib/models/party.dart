class Party {
  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final String? category;
  final String contentLanguage;
  final String? coverMediaUrl;
  final String countdownStyle;
  final String privacy;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
  final DateTime createdAt;
  final DateTime lastActivityAt;

  const Party({required this.id, required this.ownerId, required this.title, this.description, this.category, required this.contentLanguage, this.coverMediaUrl, required this.countdownStyle, required this.privacy, required this.startAt, required this.endAt, required this.status, required this.createdAt, required this.lastActivityAt});

  factory Party.fromMap(Map<String, dynamic> m) => Party(
    id: m['id'] as String,
    ownerId: m['owner_id'] as String,
    title: m['title'] as String,
    description: m['description'] as String?,
    category: m['category'] as String?,
    contentLanguage: (m['content_language'] as String?) ?? 'en',
    coverMediaUrl: m['cover_media_url'] as String?,
    countdownStyle: (m['countdown_style'] as String?) ?? 'digital',
    privacy: (m['privacy'] as String?) ?? 'public',
    startAt: DateTime.parse(m['start_at'] as String).toUtc(),
    endAt: DateTime.parse(m['end_at'] as String).toUtc(),
    status: (m['status'] as String?) ?? 'live',
    createdAt: DateTime.parse(m['created_at'] as String).toUtc(),
    lastActivityAt: DateTime.parse((m['last_activity_at'] ?? m['created_at']) as String).toUtc(),
  );
}
