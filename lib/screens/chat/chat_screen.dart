import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/inbox/inbox_models.dart';
import '../../services/inbox/inbox_repository.dart';
import '../../services/mock/mock_people.dart';
import '../../services/mock_feed_repository.dart';
import '../../services/people/people_repository.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/feed/author_avatar.dart';
import '../../widgets/feed/party_header_row.dart';
import '../../widgets/common/app_back_button.dart';

/// One-to-one conversation: history and a message box that stays above the
/// keyboard. In demo mode, sent messages are clearly marked as not delivered.
class ChatScreen extends StatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, this.conversationId = 'demo-conversation'});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _repo = InboxRepository.instance;
  final _input = TextEditingController();
  List<ChatMessage>? _messages;
  bool _failed = false, _sending = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final list = await _repo.messages(widget.conversationId);
      if (!mounted) return;
      setState(() => _messages = list);
      _repo.markRead(widget.conversationId);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final m = await _repo.send(widget.conversationId, text);
      _input.clear();
      if (mounted) setState(() => _messages = [...?_messages, m]);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Couldn\'t send. Your message is still in the box.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  bool _isMine(ChatMessage m) => m.senderId == PeopleRepository.instance.currentUserId || m.senderId == MockPeople.meId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final convo = _repo.conversation(widget.conversationId);
    final other = convo?.other;
    final party = convo?.partyId == null ? null : MockFeedRepository.instance.party(convo!.partyId!);
    final messages = _messages;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        titleSpacing: 0,
        title: other == null
            ? const Text('Chat')
            : InkWell(
                onTap: () => context.push('/u/${other.id}'),
                child: Row(children: [
                  AuthorAvatar(author: other, size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(other.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(other.handle, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ]),
                  ),
                ]),
              ),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(0.5), child: Divider()),
      ),
      body: Column(children: [
        if (!_repo.deliversMessages)
          Container(
            width: double.infinity,
            color: scheme.surfaceContainer,
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter, vertical: 8),
            child: Text('Demo chat — messages you send stay on this device and aren\'t delivered.',
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
          ),
        Expanded(
          child: _failed
              ? Center(child: ErrorState(onRetry: _load))
              : messages == null
                  ? const LoadingState()
                  : ListView(
                      reverse: true,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(Tokens.gutter, 12, Tokens.gutter, 12),
                      children: [
                        for (final m in messages.reversed) _Bubble(message: m, mine: _isMine(m)),
                        if (messages.isEmpty)
                          EmptyState(icon: Icons.waving_hand_outlined, title: 'Say hello', message: other == null ? null : 'This is the start of your chat with ${other.name}.'),
                        if (party != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: InkWell(
                              onTap: () => context.push('/p/${party.id}'),
                              borderRadius: BorderRadius.circular(Tokens.radius),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: scheme.outlineVariant),
                                  borderRadius: BorderRadius.circular(Tokens.radius),
                                ),
                                child: Row(children: [
                                  PartyThumbnail(party: party, size: 40),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(party.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text('Shared Party', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                                    ]),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ]),
                              ),
                            ),
                          ),
                      ],
                    ),
        ),
        const Divider(),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Tokens.gutter, 8, 6, 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Message',
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: scheme.outlineVariant)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: scheme.outlineVariant)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: scheme.onSurface)),
                  ),
                ),
              ),
              IconButton(
                onPressed: _input.text.trim().isEmpty || _sending ? null : _send,
                icon: const Icon(Icons.send),
                tooltip: 'Send',
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  const _Bubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = mine ? scheme.onSurface : scheme.surfaceContainer;
    final fg = mine ? scheme.surface : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
            child: DecoratedBox(
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: message.isPhoto
                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.image_outlined, size: 18, color: fg),
                        const SizedBox(width: 6),
                        Text('Photo', style: TextStyle(color: fg, fontSize: 15)),
                      ])
                    : Text(message.text, style: TextStyle(color: fg, fontSize: 15, height: 1.3)),
              ),
            ),
          ),
          if (message.delivery == MessageDelivery.notSent)
            Padding(
              padding: const EdgeInsets.only(top: 3, right: 4),
              child: Text('Not delivered · demo', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }
}
