import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';
import '../../models/feed/feed_author.dart';
import '../../models/inbox/inbox_models.dart';
import 'mock_inbox_repository.dart';
import 'supabase_inbox_repository.dart';

/// Messages and Activity. Notifies when conversations, unread state or
/// invites change.
abstract class InboxRepository extends ChangeNotifier {
  /// Demo data without a backend; the Supabase chat API otherwise.
  static InboxRepository instance = AppConfig.demoMode ? MockInboxRepository() : SupabaseInboxRepository();

  /// False when sent messages stay on this device (demo).
  bool get deliversMessages;

  /// Unread messages or pending invites (for the nav badge).
  bool get hasUnread;

  Future<List<ConversationSummary>> conversations({String query = ''});

  ConversationSummary? conversation(String id);

  Future<List<ChatMessage>> messages(String conversationId);

  Future<ChatMessage> send(String conversationId, String text);

  void markRead(String conversationId);

  /// Finds or starts a one-to-one conversation.
  Future<String> conversationWith(FeedAuthor user);

  Future<List<ActivityItem>> activity(ActivityFilter filter);

  Future<void> respondToInvite(ActivityItem item, {required bool accept});
}
