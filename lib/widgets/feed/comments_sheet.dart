import 'package:flutter/material.dart';
import '../../models/feed/feed_author.dart';
import '../../models/feed/feed_post.dart';
import '../../services/mock_feed_repository.dart';
import 'author_avatar.dart';

/// Shows the comments of one post (mock data) in a bottom sheet.
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
  final _repo = MockFeedRepository.instance;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _repo.addComment(widget.post, text));
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comments = _repo.comments(widget.post);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Column(
          children: [
            Text('Comments', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: comments.isEmpty
                  ? Center(child: Text('No comments yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)))
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
                        decoration: const InputDecoration(hintText: 'Add a comment', border: InputBorder.none, counterText: ''),
                      ),
                    ),
                    IconButton(onPressed: _send, icon: const Icon(Icons.send_outlined), tooltip: 'Send'),
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
