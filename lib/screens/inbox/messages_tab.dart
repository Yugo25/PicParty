import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/time_format.dart';
import '../../models/inbox/inbox_models.dart';
import '../../services/inbox/inbox_repository.dart';
import '../../services/mock_feed_repository.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/form_parts.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/feed/author_avatar.dart';
import '../../widgets/feed/party_header_row.dart';
import '../../l10n/l10n.dart';

/// Conversation list with search.
class MessagesTab extends StatefulWidget {
  final VoidCallback onNewMessage;
  const MessagesTab({super.key, required this.onNewMessage});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  final _repo = InboxRepository.instance;
  final _search = TextEditingController();
  Timer? _debounce;
  List<ConversationSummary>? _items;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _repo.removeListener(_load);
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await _repo.conversations(query: _search.text);
      if (!mounted) return;
      setState(() {
        _items = items;
        _failed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _retry() {
    setState(() {
      _failed = false;
      _items = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Tokens.gutter, 12, Tokens.gutter, 4),
        child: AppSearchField(
          controller: _search,
          hint: context.l10n.searchMessages,
          onChanged: (_) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 250), _load);
          },
        ),
      ),
      Expanded(
        child: _failed && items == null
            ? Center(child: SingleChildScrollView(child: ErrorState(onRetry: _retry)))
            : items == null
                ? const LoadingState()
                : items.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          child: _search.text.isEmpty
                              ? EmptyState(
                                  icon: Icons.chat_bubble_outline,
                                  title: context.l10n.noMessages,
                                  message: context.l10n.noMessagesMessage,
                                  action: OutlinedButton(onPressed: widget.onNewMessage, child: Text(context.l10n.newMessage)),
                                )
                              : EmptyState(icon: Icons.search_off, title: context.l10n.noConversationsMatch(_search.text)),
                        ),
                      )
                    : ListView.separated(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(indent: Tokens.gutter, endIndent: Tokens.gutter),
                        itemBuilder: (context, i) => _ConversationRow(c: items[i]),
                      ),
      ),
    ]);
  }
}

class _ConversationRow extends StatelessWidget {
  final ConversationSummary c;
  const _ConversationRow({required this.c});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unread = c.unread > 0;
    final party = c.partyId == null ? null : MockFeedRepository.instance.party(c.partyId!);
    final previewStyle = TextStyle(
      fontSize: 15,
      color: unread ? scheme.onSurface : scheme.onSurfaceVariant,
      fontWeight: unread ? FontWeight.w500 : FontWeight.w400,
    );
    final preview = c.lastIsPhoto
        ? Row(children: [Icon(Icons.image_outlined, size: 18, color: previewStyle.color), const SizedBox(width: 6), Text(context.l10n.sentPhoto, style: previewStyle)])
        : Text('${c.lastFromMe ? context.l10n.youPrefix : ''}${c.lastText}', maxLines: 1, overflow: TextOverflow.ellipsis, style: previewStyle);

    return Semantics(
      button: true,
      label: unread ? context.l10n.conversationUnread(c.other.name, c.unread) : c.other.name,
      child: InkWell(
        onTap: () => context.push('/chat/${c.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter, vertical: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AuthorAvatar(author: c.other, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(c.other.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                  Text(TimeFormat.ago(c.updatedAt, DateTime.now()), style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  Expanded(child: preview),
                  if (unread) ...[
                    const SizedBox(width: 8),
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: scheme.onSurface, shape: BoxShape.circle)),
                  ],
                ]),
                if (party != null) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    PartyThumbnail(party: party, size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(party.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                        Text(context.l10n.sharedParty, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                      ]),
                    ),
                  ]),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
