import 'package:flutter/material.dart';
import '../../models/feed/feed_post.dart';

/// Short caption of the post being shown, and the "View Party" link.
class PostCaption extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onViewParty;
  const PostCaption({super.key, required this.post, required this.onViewParty});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reserve one line even without a caption so the layout does not jump.
          SizedBox(
            height: 22,
            child: Text(post.caption ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15)),
          ),
          InkWell(
            onTap: onViewParty,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View Party', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
