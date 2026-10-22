import '../../models/feed/feed_author.dart';
import '../../models/inbox/inbox_models.dart';
import '../../repositories/chat_repository.dart';
import 'inbox_repository.dart';

/// Inbox backed by the existing Supabase chat API ([ChatRepository]).
///
/// The backend has no conversation-list or activity endpoint yet, so those
/// lists are empty here and the screens show their empty states.
class SupabaseInboxRepository extends InboxRepository {
  final _chat = ChatRepository();
  final _known = <String, ConversationSummary>{};

  @override
  bool get deliversMessages => true;

  @override
  bool get hasUnread => false;

  @override
  Future<List<ConversationSummary>> conversations({String query = ''}) async => const [];

  @override
  ConversationSummary? conversation(String id) => _known[id];

  @override
  Future<List<ChatMessage>> messages(String conversationId) async {
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
    return ChatMessage(id: m.id, conversationId: m.conversationId, senderId: m.senderId, text: m.content, createdAt: m.createdAt);
  }

  @override
  void markRead(String conversationId) => _chat.read(conversationId);

  @override
  Future<String> conversationWith(FeedAuthor user) async {
    final id = await _chat.getOrCreate(user.id);
    if (id == null) throw StateError('Could not open the conversation');
    _known[id] = ConversationSummary(id: id, other: user, lastText: '', updatedAt: DateTime.now());
    return id;
  }

  @override
  Future<List<ActivityItem>> activity(ActivityFilter filter) async => const [];

  @override
  Future<void> respondToInvite(ActivityItem item, {required bool accept}) => throw UnimplementedError('Invites are not connected yet');
}
