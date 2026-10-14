import 'package:flutter/foundation.dart';
import '../feed/feed_author.dart';

/// One row of the Messages list: a one-to-one conversation.
@immutable
class ConversationSummary {
  final String id;
  final FeedAuthor other;
  final String lastText;
  final bool lastIsPhoto, lastFromMe;
  final DateTime updatedAt;
  final int unread;

  /// A Party both people are in, shown as context when useful.
  final String? partyId;

  const ConversationSummary({
    required this.id,
    required this.other,
    required this.lastText,
    this.lastIsPhoto = false,
    this.lastFromMe = false,
    required this.updatedAt,
    this.unread = 0,
    this.partyId,
  });

  bool get isEmpty => lastText.isEmpty && !lastIsPhoto;

  ConversationSummary copyWith({String? lastText, bool? lastIsPhoto, bool? lastFromMe, DateTime? updatedAt, int? unread}) =>
      ConversationSummary(
        id: id,
        other: other,
        lastText: lastText ?? this.lastText,
        lastIsPhoto: lastIsPhoto ?? this.lastIsPhoto,
        lastFromMe: lastFromMe ?? this.lastFromMe,
        updatedAt: updatedAt ?? this.updatedAt,
        unread: unread ?? this.unread,
        partyId: partyId,
      );
}

/// Whether a message actually reached the server.
enum MessageDelivery {
  sent,

  /// Demo only: kept on this device, never delivered.
  notSent,
}

@immutable
class ChatMessage {
  final String id, conversationId, senderId, text;
  final bool isPhoto;
  final DateTime createdAt;
  final MessageDelivery delivery;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.isPhoto = false,
    required this.createdAt,
    this.delivery = MessageDelivery.sent,
  });
}

enum ActivityKind { invite, like, comment, follow, reminder }

enum InviteStatus { pending, accepted, declined }

enum ActivityFilter {
  all('All'),
  invites('Invites'),
  interactions('Interactions');

  final String label;
  const ActivityFilter(this.label);

  bool includes(ActivityKind kind) => switch (this) {
        ActivityFilter.all => true,
        ActivityFilter.invites => kind == ActivityKind.invite,
        ActivityFilter.interactions => kind == ActivityKind.like || kind == ActivityKind.comment || kind == ActivityKind.follow,
      };
}

/// One notification in Activity.
///
/// Reminders store only the Party id, never a "minutes left" figure, so the
/// row is always worded from the Party's current state.
class ActivityItem {
  final String id;
  final ActivityKind kind;
  final FeedAuthor? actor;
  final String? partyId, postId, comment;
  final DateTime createdAt;
  InviteStatus inviteStatus;

  ActivityItem({
    required this.id,
    required this.kind,
    this.actor,
    this.partyId,
    this.postId,
    this.comment,
    required this.createdAt,
    this.inviteStatus = InviteStatus.pending,
  });
}
