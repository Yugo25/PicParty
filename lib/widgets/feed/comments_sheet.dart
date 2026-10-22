import 'package:flutter/material.dart';
import '../../models/comment.dart';
import '../../models/feed/feed_author.dart';
import '../../models/feed/feed_post.dart';
import '../../services/feed/feed_repository.dart';
import '../common/form_parts.dart';
import '../common/state_views.dart';
import 'author_avatar.dart';
import '../../l10n/l10n.dart';

/// Shows the comments of one post in a bottom sheet.
Future<void> showCommentsSheet(BuildContext context, FeedPost post) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (_) => _CommentsSheet(post: post),
    );

class _CommentsSheet extends StatefulWidget {
  final FeedPost post;
  const _CommentsSheet({required this.post});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _input = TextEditingController();
  final _repo = FeedRepository.instance;
  List<Comment>? _comments;
  bool _failed = false, _sending = false;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_failed) setState(() => _failed = false);
    try {
      final list = await _repo.comments(widget.post);
      if (mounted) setState(() => _comments = list);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      await _repo.addComment(widget.post, text);
      _input.clear();
      await _load();
    } catch (_) {
      // The text stays in the box so it can be sent again.
      if (mounted) setState(() => _sendError = context.l10n.commentFailed);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comments = _comments;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Column(
          children: [
            Text(context.l10n.comments, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: comments == null
                  ? (_failed ? Center(child: ErrorState(onRetry: _load)) : const LoadingState())
                  : comments.isEmpty
                  ? Center(child: Text(context.l10n.noComments, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)))
                  : ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, i) {
                        final c = comments[i];
                        return ListTile(
                          leading: AuthorAvatar(author: FeedAuthor(id: c.userId, username: c.username ?? 'user', avatarUrl: c.avatarUrl)),
                          title: Text('@${c.username ?? 'user'}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          subtitle: Text(c.content, style: theme.textTheme.bodyMedium),
                        );
                      },
                    ),
            ),
            const Divider(),
            if (_sendError != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: FieldError(_sendError)),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        maxLength: 500,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(hintText: context.l10n.addComment, border: InputBorder.none, counterText: ''),
                      ),
                    ),
                    IconButton(onPressed: _sending ? null : _send, icon: const Icon(Icons.send_outlined), tooltip: context.l10n.send),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
