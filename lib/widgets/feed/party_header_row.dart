import 'package:flutter/material.dart';
import '../../models/feed/feed_party.dart';
import '../../models/feed/feed_post.dart';
import 'feed_media_view.dart';

/// Thumbnail, Party name, contributor count and the menu button.
class PartyHeaderRow extends StatelessWidget {
  final FeedParty party;
  final VoidCallback onOpenParty;
  final VoidCallback onMenu;
  const PartyHeaderRow({super.key, required this.party, required this.onOpenParty, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpenParty,
              child: Row(
                children: [
                  PartyThumbnail(url: party.thumbnailUrl, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(party.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 1),
                        Text('${party.contributorCount} ${party.contributorCount == 1 ? 'contributor' : 'contributors'}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(onPressed: onMenu, icon: const Icon(Icons.more_horiz), tooltip: 'More'),
        ],
      ),
    );
  }
}

/// Small square Party thumbnail with slightly rounded corners.
class PartyThumbnail extends StatelessWidget {
  final SizedImageUrl url;
  final double size;
  const PartyThumbnail({super.key, required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final px = requestPixelSize(context, Size.square(size));
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox.square(
        dimension: size,
        child: Image.network(
          url(px.width.toInt(), px.height.toInt()),
          fit: BoxFit.cover,
          cacheWidth: px.width.toInt(),
          frameBuilder: (context, child, frame, wasSync) => wasSync || frame != null ? child : const MediaPlaceholder(),
          errorBuilder: (context, error, stack) => const MediaPlaceholder(),
        ),
      ),
    );
  }
}
