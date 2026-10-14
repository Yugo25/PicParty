import 'package:flutter/foundation.dart';
import 'feed_author.dart';

enum FeedMediaType { photo, video }

/// Like / comment state of one post. Held in a [ValueNotifier] on the post so
/// only the action row rebuilds when it changes.
@immutable
class PostReactions {
  final int likeCount, commentCount;
  final bool liked;

  const PostReactions({required this.likeCount, required this.commentCount, this.liked = false});

  PostReactions copyWith({int? likeCount, int? commentCount, bool? liked}) => PostReactions(
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        liked: liked ?? this.liked,
      );
}

/// Signature for building an image URL sized for the space it is shown in.
typedef SizedImageUrl = String Function(int width, int height);

/// One photo or video posted into a Party.
class FeedPost {
  final String id, partyId;
  final FeedAuthor author;
  final FeedMediaType type;

  /// Builds a URL for the photo (or the video's poster) at a given pixel size,
  /// so lists never download full-size originals.
  final SizedImageUrl? imageUrl;

  /// Path / blob URL of a photo the user added locally in this demo session.
  final String? localPath;

  final String? videoUrl;
  final String? caption;
  final DateTime createdAt;
  final ValueNotifier<PostReactions> reactions;

  FeedPost({
    required this.id,
    required this.partyId,
    required this.author,
    required this.type,
    this.imageUrl,
    this.localPath,
    this.videoUrl,
    this.caption,
    required this.createdAt,
    required PostReactions reactions,
  }) : reactions = ValueNotifier(reactions);

  bool get isVideo => type == FeedMediaType.video;
}
