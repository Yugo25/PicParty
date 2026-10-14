import 'package:flutter/material.dart';
import '../../models/feed/feed_post.dart';
import 'author_avatar.dart';

/// Author of the post being shown, plus like / comment / share for that post.
class PostActionBar extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onLike;
  final VoidCallback onComments;
  final VoidCallback onShare;

  const PostActionBar({super.key, required this.post, required this.onLike, required this.onComments, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 6, 2),
      child: Row(
        children: [
          AuthorAvatar(author: post.author, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(post.author.handle,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
          ValueListenableBuilder<PostReactions>(
            valueListenable: post.reactions,
            builder: (context, r, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CountButton(
                  icon: r.liked ? Icons.favorite : Icons.favorite_border,
                  color: r.liked ? const Color(0xFFE5484D) : null,
                  count: r.likeCount,
                  label: r.liked ? 'Unlike' : 'Like',
                  onTap: onLike,
                ),
                _CountButton(icon: Icons.chat_bubble_outline, count: r.commentCount, label: 'Comments', onTap: onComments),
              ],
            ),
          ),
          IconButton(onPressed: onShare, icon: const Icon(Icons.ios_share), tooltip: 'Share', iconSize: 22),
        ],
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final int count;
  final String label;
  final VoidCallback onTap;
  const _CountButton({required this.icon, this.color, required this.count, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$label, $count',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 22, color: color),
                    const SizedBox(width: 5),
                    Text('$count', style: const TextStyle(fontSize: 14, fontFeatures: [FontFeature.tabularFigures()])),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
