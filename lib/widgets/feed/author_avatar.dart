import 'package:flutter/material.dart';
import '../../models/feed/feed_author.dart';
import 'feed_media_view.dart';

/// Round avatar with an initial as fallback while loading or on error.
class AuthorAvatar extends StatelessWidget {
  final FeedAuthor author;
  final double size;
  const AuthorAvatar({super.key, required this.author, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: scheme.surfaceContainerHigh,
      child: Text(author.initial, style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
    );
    final px = (size * MediaQuery.devicePixelRatioOf(context)).ceil();
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: author.avatarUrl == null
            ? fallback
            : Image(
                image: networkImageProvider(author.avatarUrl!, cacheWidth: px),
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, wasSync) => wasSync || frame != null ? child : fallback,
                errorBuilder: (context, error, stack) => fallback,
              ),
      ),
    );
  }
}
