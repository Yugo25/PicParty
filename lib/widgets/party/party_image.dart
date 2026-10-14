import 'package:flutter/material.dart';
import '../../models/feed/feed_party.dart';
import '../../models/feed/feed_post.dart';
import '../feed/feed_media_view.dart';
import '../media/local_media_image.dart';

/// A network image requested at the pixel size it is drawn at, with a neutral
/// placeholder while loading and on error (same size, so nothing jumps).
class SizedNetworkImage extends StatelessWidget {
  final SizedImageUrl url;
  final BoxFit fit;
  const SizedNetworkImage({super.key, required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final px = requestPixelSize(context, constraints.biggest);
        return Image(
          image: networkImageProvider(url(px.width.toInt(), px.height.toInt()), cacheWidth: px.width.toInt()),
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSync) => wasSync || frame != null ? child : const MediaPlaceholder(),
          errorBuilder: (context, error, stack) => const MediaPlaceholder(error: true),
        );
      });
}

/// The picture that stands for a Party in lists: its newest photo (a video's
/// poster, never the video itself), or the cover until someone has posted.
class PartyImage extends StatelessWidget {
  final FeedParty party;

  /// Show the cover even when posts exist.
  final bool coverOnly;

  const PartyImage({super.key, required this.party, this.coverOnly = false});

  @override
  Widget build(BuildContext context) {
    if (!coverOnly) {
      for (final post in party.posts) {
        if (post.imageUrl != null || (post.localPath != null && !post.isVideo)) return PostImage(post: post);
      }
    }
    if (party.coverLocalPath != null) return LocalMediaImage(path: party.coverLocalPath!);
    if (party.thumbnailUrl != null) return SizedNetworkImage(url: party.thumbnailUrl!);
    return const MediaPlaceholder();
  }
}

/// A post's photo (or a video's poster) as a still image.
class PostImage extends StatelessWidget {
  final FeedPost post;
  const PostImage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    if (post.localPath != null && !post.isVideo) return LocalMediaImage(path: post.localPath!);
    if (post.imageUrl != null) return SizedNetworkImage(url: post.imageUrl!);
    return const MediaPlaceholder();
  }
}

/// Square post thumbnail for grids, with a video marker. Tapping is up to the parent.
class PostThumbnail extends StatelessWidget {
  final FeedPost post;
  const PostThumbnail({super.key, required this.post});

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        PostImage(post: post),
        if (post.isVideo)
          const Positioned(
            top: 6,
            right: 6,
            child: Icon(Icons.videocam_outlined, color: Colors.white, size: 18, semanticLabel: 'Video', shadows: [Shadow(color: Color(0x66000000), blurRadius: 4)]),
          ),
      ]);
}
