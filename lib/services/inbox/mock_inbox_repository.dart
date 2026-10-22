import '../../models/feed/feed_author.dart';
import '../../models/inbox/inbox_models.dart';
import '../mock/mock_network.dart';
import '../mock/mock_people.dart';
import '../mock_feed_repository.dart';
import 'inbox_repository.dart';

/// Demo conversations and notifications, kept in memory. Messages "sent" here
/// are never delivered and are marked [MessageDelivery.notSent].
class MockInboxRepository extends InboxRepository {
  MockInboxRepository() {
    _seed(DateTime.now());
  }

  final _conversations = <String, ConversationSummary>{};
  final _messages = <String, List<ChatMessage>>{};
  final _activity = <ActivityItem>[];

  @override
  bool get deliversMessages => false;

  @override
  bool get hasUnread =>
      _conversations.values.any((c) => c.unread > 0) ||
      _activity.any((a) => a.kind == ActivityKind.invite && a.inviteStatus == InviteStatus.pending);

  @override
  Future<List<ConversationSummary>> conversations({String query = ''}) async {
    await MockNetwork.request();
    final q = query.trim().toLowerCase();
    final list = _conversations.values.where((c) {
      if (c.isEmpty) return false;
      if (q.isEmpty) return true;
      return c.other.name.toLowerCase().contains(q) || c.other.username.toLowerCase().contains(q) || c.lastText.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  ConversationSummary? conversation(String id) => _conversations[id];

  @override
  Future<List<ChatMessage>> messages(String conversationId) async {
    await MockNetwork.request(const Duration(milliseconds: 200));
    return List.of(_messages[conversationId] ?? const []);
  }

  @override
  Future<ChatMessage> send(String conversationId, String text) async {
    final now = DateTime.now();
    final m = ChatMessage(
      id: 'm-${now.microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: MockPeople.meId,
      text: text,
      createdAt: now,
      delivery: MessageDelivery.notSent,
    );
    _messages.putIfAbsent(conversationId, () => []).add(m);
    final c = _conversations[conversationId];
    if (c != null) _conversations[conversationId] = c.copyWith(lastText: text, lastIsPhoto: false, lastFromMe: true, updatedAt: now);
    notifyListeners();
    return m;
  }

  @override
  void markRead(String conversationId) {
    final c = _conversations[conversationId];
    if (c == null || c.unread == 0) return;
    _conversations[conversationId] = c.copyWith(unread: 0);
    notifyListeners();
  }

  @override
  Future<String> conversationWith(FeedAuthor user) async {
    for (final c in _conversations.values) {
      if (c.other.id == user.id) return c.id;
    }
    final id = 'c-${user.id}';
    _conversations[id] = ConversationSummary(id: id, other: user, lastText: '', updatedAt: DateTime.now());
    return id;
  }

  @override
  Future<List<ActivityItem>> activity(ActivityFilter filter) async {
    await MockNetwork.request();
    return _activity.where((a) => filter.includes(a.kind)).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> respondToInvite(ActivityItem item, {required bool accept}) async {
    await MockNetwork.request(const Duration(milliseconds: 250));
    item.inviteStatus = accept ? InviteStatus.accepted : InviteStatus.declined;
    if (accept && item.partyId != null) MockFeedRepository.instance.join(item.partyId!);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Seed data

  void _seed(DateTime now) {
    const me = MockPeople.meId;
    void convo(String id, FeedAuthor other, List<(bool mine, String text, int minutesAgo)> lines,
        {int unread = 0, String? partyId, bool lastIsPhoto = false}) {
      _messages[id] = [
        for (var i = 0; i < lines.length; i++)
          ChatMessage(
            id: '$id-$i',
            conversationId: id,
            senderId: lines[i].$1 ? me : other.id,
            text: lines[i].$2,
            isPhoto: lastIsPhoto && i == lines.length - 1,
            createdAt: now.subtract(Duration(minutes: lines[i].$3)),
          ),
      ];
      final last = lines.last;
      _conversations[id] = ConversationSummary(
        id: id,
        other: other,
        lastText: last.$2,
        lastIsPhoto: lastIsPhoto,
        lastFromMe: last.$1,
        updatedAt: now.subtract(Duration(minutes: last.$3)),
        unread: unread,
        partyId: partyId,
      );
    }

    convo('c-u1', MockPeople.sarah, [
      (true, 'Your shot from the market was so good.', 95),
      (false, 'Thank you! I added a few more to Street snaps.', 40),
      (false, 'Did you see the new photos?', 12),
    ], unread: 1, partyId: 'street');
    convo('c-u2', MockPeople.kenji, [
      (false, 'Were you at the river this evening?', 70),
      (true, 'Yes, just before sunset.', 52),
      (false, 'That light was incredible.', 35),
    ], unread: 2);
    convo('c-u4', MockPeople.alex, [
      (true, 'The trail photos came out great.', 180),
      (false, 'Let\'s start a Party this weekend.', 60),
    ]);
    convo('c-u3', MockPeople.maya, [
      (false, 'Here\'s the view from the bridge.', 130),
      (false, 'Photo', 120),
    ], lastIsPhoto: true);
    convo('c-u6', MockPeople.daniel, [
      (true, 'Posted mine to the coast Party.', 320),
      (false, 'That sunset was amazing!', 300),
    ]);
    convo('c-u8', MockPeople.priya, [
      (false, 'Thanks for hosting!', 1500),
      (true, 'Thanks for coming.', 1460),
      (false, 'See you at the next one!', 1440),
    ]);

    final feed = MockFeedRepository.instance;
    DateTime reminderTime(String partyId) {
      final p = feed.party(partyId);
      // Sent 30 minutes before the Party's end.
      return p == null ? now : p.endAt.subtract(const Duration(minutes: 30));
    }

    _activity.addAll([
      ActivityItem(id: 'a1', kind: ActivityKind.invite, actor: MockPeople.maya, partyId: 'montreal', createdAt: now.subtract(const Duration(minutes: 12))),
      ActivityItem(id: 'a2', kind: ActivityKind.like, actor: MockPeople.kenji, partyId: 'kyoto', postId: 'kyoto-2', createdAt: now.subtract(const Duration(minutes: 40))),
      ActivityItem(
          id: 'a3',
          kind: ActivityKind.comment,
          actor: MockPeople.sarah,
          partyId: 'coast',
          postId: 'coast-1',
          comment: 'Love this moment.',
          createdAt: now.subtract(const Duration(hours: 1, minutes: 5))),
      ActivityItem(id: 'a4', kind: ActivityKind.follow, actor: MockPeople.alex, createdAt: now.subtract(const Duration(hours: 2))),
      ActivityItem(id: 'a5', kind: ActivityKind.reminder, partyId: 'coffee', createdAt: reminderTime('coffee')),
      ActivityItem(id: 'a6', kind: ActivityKind.reminder, partyId: 'autumn', createdAt: reminderTime('autumn')),
      ActivityItem(id: 'a7', kind: ActivityKind.invite, actor: MockPeople.theo, partyId: 'studio', createdAt: now.subtract(const Duration(days: 1, hours: 2))),
      ActivityItem(id: 'a8', kind: ActivityKind.follow, actor: MockPeople.priya, createdAt: now.subtract(const Duration(days: 2))),
      ActivityItem(id: 'a9', kind: ActivityKind.like, actor: MockPeople.daniel, partyId: 'banff', postId: 'banff-0', createdAt: now.subtract(const Duration(days: 3))),
    ]);
  }
}
