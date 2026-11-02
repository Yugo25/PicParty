import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../models/feed/feed_author.dart';
import '../../models/inbox/inbox_models.dart';
import '../../repositories/chat_repository.dart';
import 'inbox_repository.dart';

/// Inbox backed by the Supabase chat API ([ChatRepository] and
/// `get_conversations` from 118_chat.sql).
///
/// The backend has no activity endpoint yet, so that list is empty here and
/// the screen shows its empty state.
class SupabaseInboxRepository extends InboxRepository {
  SupabaseClient get _client => SupabaseConfig.client;
  final _chat = ChatRepository();

  /// Conversations seen in the list or opened from a profile, for [conversation].
  final _known = <String, ConversationSummary>{};
  bool _hasUnread = false;

  @override
  bool get deliversMessages => true;

  @override
  bool get hasUnread => _hasUnread;

  @override
  Future<List<ConversationSummary>> conversations({String query = ''}) async {
    final me = _client.auth.currentUser?.id;
    final rows = await _client.rpc('get_conversations') as List;
    final all = [for (final r in rows) _summary(Map<String, dynamic>.from(r as Map), me)];
    for (final c in all) {
      _known[c.id] = c;
    }
    _setUnread(all.any((c) => c.unread > 0));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((c) => c.other.name.toLowerCase().contains(q) || c.other.username.toLowerCase().contains(q) || c.lastText.toLowerCase().contains(q))
        .toList();
  }

  @override
  ConversationSummary? conversation(String id) => _known[id];

  @override
  Future<List<ChatMessage>> messages(String conversationId) async {
    // Opened straight from a link: load the list once so the header can show who it's with.
    if (!_known.containsKey(conversationId)) await conversations();
    final list = await _chat.messages(conversationId);
    return [
      for (final m in list.reversed)
        ChatMessage(id: m.id, conversationId: m.conversationId, senderId: m.senderId, text: m.content, createdAt: m.createdAt),
    ];
  }

  @override
  Future<ChatMessage> send(String conversationId, String text) async {
    final m = await _chat.send(conversationId, text);
    if (m == null) throw StateError('Message was not sent');
    final c = _known[conversationId];
    if (c != null) {
      _known[conversationId] = c.copyWith(lastText: m.content, lastIsPhoto: false, lastFromMe: true, updatedAt: m.createdAt);
      notifyListeners();
    }
    return ChatMessage(id: m.id, conversationId: m.conversationId, senderId: m.senderId, text: m.content, createdAt: m.createdAt);
  }

  @override
  void markRead(String conversationId) {
    _chat.read(conversationId).then((_) {
      final c = _known[conversationId];
      if (c == null || c.unread == 0) return;
      _known[conversationId] = c.copyWith(unread: 0);
      _hasUnread = _known.values.any((c) => c.unread > 0);
      notifyListeners();
    }, onError: (_) {
      // Stays unread; the next visit tries again.
    });
  }

  @override
  Future<String> conversationWith(FeedAuthor user) async {
    final id = await _chat.getOrCreate(user.id);
    if (id == null) throw StateError('Could not open the conversation');
    _known.putIfAbsent(id, () => ConversationSummary(id: id, other: user, lastText: '', updatedAt: DateTime.now()));
    return id;
  }

  @override
  Future<List<ActivityItem>> activity(ActivityFilter filter) async => const [];

  @override
  Future<void> respondToInvite(ActivityItem item, {required bool accept}) => throw UnimplementedError('Invites are not connected yet');

  @override
  void clearCache() {
    _known.clear();
    _hasUnread = false;
    notifyListeners();
  }

  /// Only notifies on a change, so screens that reload when notified don't loop.
  void _setUnread(bool value) {
    if (value == _hasUnread) return;
    _hasUnread = value;
    notifyListeners();
  }

  static ConversationSummary _summary(Map<String, dynamic> r, String? me) {
    final other = Map<String, dynamic>.from(r['other'] as Map);
    return ConversationSummary(
      id: r['id'] as String,
      other: FeedAuthor(
        id: other['id'] as String,
        username: other['username'] as String,
        displayName: other['display_name'] as String?,
        avatarUrl: other['avatar_url'] as String?,
      ),
      lastText: r['last_text'] as String,
      lastFromMe: r['last_sender_id'] == me,
      updatedAt: DateTime.parse(r['updated_at'] as String).toLocal(),
      unread: (r['unread'] as num).toInt(),
    );
  }
}
