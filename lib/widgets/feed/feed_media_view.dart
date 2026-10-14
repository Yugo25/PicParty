import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/feed/feed_post.dart';
import '../../services/feed/video_playback_coordinator.dart';
import '../media/local_media_image.dart';

/// Pixel size to request for an image shown at [logical] size, rounded up to a
/// step so nearby sizes share one cached download.
Size requestPixelSize(BuildContext context, Size logical) {
  final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0);
  int up(double v) => ((v * dpr / 120).ceil() * 120).clamp(120, 2400);
  return Size(up(logical.width).toDouble(), up(logical.height).toDouble());
}

/// Network image decoded at [cacheWidth]. Native builds keep a disk cache;
/// on web the browser's HTTP cache does that job, and the cached provider's
/// HTML-image path renders unreliably there.
ImageProvider networkImageProvider(String url, {required int cacheWidth}) => kIsWeb
    ? ResizeImage(NetworkImage(url), width: cacheWidth, policy: ResizeImagePolicy.fit) as ImageProvider
    : CachedNetworkImageProvider(url, maxWidth: cacheWidth);

/// Provider for a post's photo (or video poster) at a pixel size.
ImageProvider? postImageProvider(FeedPost post, Size px) {
  final url = post.imageUrl?.call(px.width.toInt(), px.height.toInt());
  return url == null ? null : networkImageProvider(url, cacheWidth: px.width.toInt());
}

/// A post's photo or video, filling its box. Loading and error states keep the
/// same size so the layout never jumps.
class FeedMediaView extends StatelessWidget {
  final FeedPost post;

  /// Whether a video post should load and play now. Photos ignore it.
  final bool play;
  final VoidCallback? onVideoCompleted;
  final BoxFit fit;

  const FeedMediaView({super.key, required this.post, this.play = false, this.onVideoCompleted, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final photo = _PostPhoto(post: post, fit: fit);
    if (!post.isVideo) return photo;
    return Stack(fit: StackFit.expand, children: [
      photo, // poster, shown first and kept underneath while the video loads
      if (play && post.videoUrl != null) _FeedVideo(url: post.videoUrl!, fit: fit, onCompleted: onVideoCompleted),
      const Positioned(top: 12, left: 12, child: _VideoBadge()),
    ]);
  }
}

class _PostPhoto extends StatelessWidget {
  final FeedPost post;
  final BoxFit fit;
  const _PostPhoto({required this.post, required this.fit});

  @override
  Widget build(BuildContext context) {
    if (post.localPath != null && !post.isVideo) return LocalMediaImage(path: post.localPath!, fit: fit);
    return LayoutBuilder(builder: (context, constraints) {
      final px = requestPixelSize(context, constraints.biggest);
      final provider = postImageProvider(post, px);
      if (provider == null) return const MediaPlaceholder(error: true);
      return Image(
        image: provider,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSync) =>
            wasSync || frame != null ? child : const MediaPlaceholder(),
        errorBuilder: (context, error, stack) => const MediaPlaceholder(error: true),
      );
    });
  }
}

/// Neutral box shown while media loads or when it fails.
class MediaPlaceholder extends StatelessWidget {
  final bool error;
  const MediaPlaceholder({super.key, this.error = false});

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: const Color(0xFF2A2A2A),
        child: error
            ? const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 32, semanticLabel: 'Media unavailable'))
            : const SizedBox.expand(),
      );
}

class _VideoBadge extends StatelessWidget {
  const _VideoBadge();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(color: Color(0x66000000), borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Icon(Icons.videocam_outlined, size: 16, color: Colors.white, semanticLabel: 'Video'),
        ),
      );
}

/// Loads a video only when asked to play, muted (so browsers allow autoplay),
/// and disposes it as soon as it is no longer needed.
class _FeedVideo extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final VoidCallback? onCompleted;
  const _FeedVideo({required this.url, required this.fit, this.onCompleted});

  @override
  State<_FeedVideo> createState() => _FeedVideoState();
}

class _FeedVideoState extends State<_FeedVideo> {
  VideoPlayerController? _controller;
  bool _ready = false, _completed = false;

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = c;
    VideoPlaybackCoordinator.instance.claim(this, () => _controller?.pause());
    c.addListener(_onTick);
    c.initialize().then((_) async {
      if (!mounted || _controller != c) return;
      await c.setVolume(0);
      await c.play();
      if (mounted) setState(() => _ready = true);
    }).catchError((Object _) {});
  }

  void _onTick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final done = c.value.position >= c.value.duration && c.value.duration > Duration.zero;
    if (done && !_completed) {
      _completed = true;
      widget.onCompleted?.call();
      // Loop when nothing advances us away.
      if (!mounted) return;
      c.seekTo(Duration.zero).then((_) {
        _completed = false;
        if (mounted && _controller == c) c.play();
      }).catchError((Object _) {});
    }
  }

  @override
  void dispose() {
    VideoPlaybackCoordinator.instance.release(this);
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null || !_ready) return const SizedBox.shrink();
    return FittedBox(
      fit: widget.fit,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)),
    );
  }
}
