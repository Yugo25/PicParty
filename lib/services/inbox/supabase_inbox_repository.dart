import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../models/feed/feed_author.dart';
import '../../models/inbox/inbox_models.dart';
import '../../repositories/chat_repository.dart';
import '../feed/feed_repository.dart';
import 'inbox_repository.dart';

/// Inbox backed by Supabase: messages through [ChatRepository] and
/// 118_chat.sql, Activity and the unread dot through 119_activity.sql.
///
/// Invites aren't connected yet (nothing in the app sends them).
class SupabaseInboxRepository extends InboxRepository {
  SupabaseClient get _client => SupabaseConfig.client;
  final _chat = ChatRepository();

  /// Conversations seen in the list or opened from a profile, for [conversation].
  final _known = <String, ConversationSummary>{};
  bool _unreadMessages = false, _unreadActivity = false;

  @override
  bool get deliversMessages => true;

  @override
  bool get hasUnread => _unreadMessages || _unreadActivity;

  @override
  Future<void> refreshUnread() async {
    try {
      final r = Map<String, dynamic>.from(await _client.rpc('get_inbox_unread') as Map);
      _setUnread(messages: r['messages'] == true, activity: r['activity'] == true);
    } catch (_) {
      // The dot just stays as it was.
    }
  }

  @override
  Future<List<ConversationSummary>> conversations({String query = ''}) async {
    final me = _client.auth.currentUser?.id;
    final rows = await _client.rpc('get_conversations') as List;
    final all = [for (final r in rows) _summary(Map<String, dynamic>.from(r as Map), me)];
    for (final c in all) {
      _known[c.id] = c;
    }
    _setUnread(messages: all.any((c) => c.unread > 0));
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
      _unreadMessages = _known.values.any((c) => c.unread > 0);
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
  Future<List<ActivityItem>> activity(ActivityFilter filter) async {
    final rows = await _client.rpc('get_activity') as List;
    final items = [for (final r in rows) _activityItem(Map<String, dynamic>.from(r as Map))];
    await _loadParties(items);
    _markActivitySeen();
    return items.where((a) => filter.includes(a.kind)).toList();
  }

  @override
  Future<void> respondToInvite(ActivityItem item, {required bool accept}) => throw UnimplementedError('Invites are not connected yet');

  @override
  void clearCache() {
    _known.clear();
    _unreadMessages = _unreadActivity = false;
    notifyListeners();
  }

  /// Only notifies when the dot changes, so screens that reload when notified don't loop.
  void _setUnread({bool? messages, bool? activity}) {
    final before = hasUnread;
    _unreadMessages = messages ?? _unreadMessages;
    _unreadActivity = activity ?? _unreadActivity;
    if (hasUnread != before) notifyListeners();
  }

  /// Activity has been looked at: clears its part of the dot.
  void _markActivitySeen() {
    _client.rpc('mark_all_notifications_read').then((_) => _setUnread(activity: false), onError: (_) {
      // Stays unread; the next visit tries again.
    });
  }

  /// Activity rows draw their Party and post from [FeedRepository]; loads the
  /// Parties it doesn't have yet (or has without that post).
  static Future<void> _loadParties(List<ActivityItem> items) async {
    final feed = FeedRepository.instance;
    final missing = <String>{
      for (final a in items)
        if (a.partyId != null && (feed.party(a.partyId!)?.posts.every((p) => p.id != a.postId) ?? true)) a.partyId!,
    };
    // A Party that fails to load just shows its row without a thumbnail.
    await Future.wait([for (final id in missing) feed.loadParty(id).catchError((_) => null)]);
  }

  static FeedAuthor _author(Map r) => FeedAuthor(
        id: r['id'] as String,
        username: r['username'] as String,
        displayName: r['display_name'] as String?,
        avatarUrl: r['avatar_url'] as String?,
      );

  static ConversationSummary _summary(Map<String, dynamic> r, String? me) => ConversationSummary(
        id: r['id'] as String,
        other: _author(r['other'] as Map),
        lastText: r['last_text'] as String,
        lastFromMe: r['last_sender_id'] == me,
        updatedAt: DateTime.parse(r['updated_at'] as String).toLocal(),
        unread: (r['unread'] as num).toInt(),
      );

  /// Replies are shown like comments.
  static ActivityItem _activityItem(Map<String, dynamic> r) => ActivityItem(
        id: r['id'] as String,
        kind: switch (r['type']) {
          'like' => ActivityKind.like,
          'follow' => ActivityKind.follow,
          _ => ActivityKind.comment,
        },
        actor: _author(r['actor'] as Map),
        partyId: r['party_id'] as String?,
        postId: r['media_id'] as String?,
        comment: r['comment'] as String?,
        createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
      );
}
