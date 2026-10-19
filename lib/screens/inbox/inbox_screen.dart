import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/feed/feed_author.dart';
import '../../services/explore/explore_repository.dart';
import '../../services/inbox/inbox_repository.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/form_parts.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/common/underline_tabs.dart';
import '../../widgets/feed/author_avatar.dart';
import 'activity_tab.dart';
import 'messages_tab.dart';
import '../../l10n/l10n.dart';

enum InboxTab { messages, activity }

/// Inbox: one-to-one Messages, and Activity (invites, likes, comments,
/// follows, reminders).
class InboxScreen extends StatefulWidget {
  final InboxTab initialTab;
  const InboxScreen({super.key, this.initialTab = InboxTab.messages});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late InboxTab _tab = widget.initialTab;

  @override
  void didUpdateWidget(InboxScreen old) {
    super.didUpdateWidget(old);
    if (old.initialTab != widget.initialTab) _tab = widget.initialTab;
  }

  Future<void> _newMessage() async {
    final person = await showModalBottomSheet<FeedAuthor>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _NewMessageSheet(),
    );
    if (person == null || !mounted) return;
    final id = await InboxRepository.instance.conversationWith(person);
    if (mounted) context.push('/chat/$id');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Stack(children: [
              Center(
                child: Semantics(
                  header: true,
                  child: Text(context.l10n.inbox, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700)),
                ),
              ),
              Positioned(
                right: 4,
                top: 0,
                bottom: 0,
                child: IconButton(onPressed: _newMessage, icon: const Icon(Icons.edit_square), tooltip: context.l10n.newMessage),
              ),
            ]),
          ),
          UnderlineTabs<InboxTab>(
            values: InboxTab.values,
            selected: _tab,
            labelOf: (t) => t == InboxTab.messages ? context.l10n.messages : context.l10n.activity,
            onSelected: (t) => setState(() => _tab = t),
            fontSize: 16,
          ),
          Expanded(
            // Both tabs stay alive so switching keeps their scroll and search.
            child: IndexedStack(
              index: _tab.index,
              children: [
                MessagesTab(onNewMessage: _newMessage),
                const ActivityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pick someone to message.
class _NewMessageSheet extends StatefulWidget {
  const _NewMessageSheet();

  @override
  State<_NewMessageSheet> createState() => _NewMessageSheetState();
}

class _NewMessageSheetState extends State<_NewMessageSheet> {
  final _search = TextEditingController();
  late Future<List<FeedAuthor>> _people = _load('');

  Future<List<FeedAuthor>> _load(String q) => ExploreRepository.instance.people(q, page: 0, pageSize: 50);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(children: [
          Text(context.l10n.newMessage, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          Padding(
            padding: const EdgeInsets.fromLTRB(Tokens.gutter, 12, Tokens.gutter, 8),
            child: AppSearchField(
              controller: _search,
              hint: context.l10n.searchPeople,
              onChanged: (q) => setState(() => _people = _load(q)),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<FeedAuthor>>(
              future: _people,
              builder: (context, snap) {
                if (snap.hasError) return ErrorState(onRetry: () => setState(() => _people = _load(_search.text)));
                if (!snap.hasData) return const LoadingState();
                final list = snap.data!;
                if (list.isEmpty) return EmptyState(icon: Icons.person_search_outlined, title: context.l10n.noPeopleFound);
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) => ListTile(
                    leading: AuthorAvatar(author: list[i], size: 40),
                    title: Text(list[i].name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(list[i].handle),
                    onTap: () => Navigator.of(context).pop(list[i]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
