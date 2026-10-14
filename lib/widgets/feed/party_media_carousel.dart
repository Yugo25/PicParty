import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../config/feed_config.dart';
import '../../models/feed/feed_party.dart';
import '../../services/feed/auto_advance_controller.dart';
import '../countdown/countdown_style.dart';
import '../countdown/photo_countdown_overlay.dart';
import 'feed_media_view.dart';
import 'page_dots.dart';

/// The photo-backed countdown area of a Party.
///
/// Only the background media layer ([PageView]) moves on a horizontal swipe.
/// The gradient, timer, post counter, dots and play button are fixed on top,
/// so the deadline never shifts while posts change. The box has a fixed
/// aspect ratio, so the Party's height never changes either.
class PartyMediaCarousel extends StatefulWidget {
  final FeedParty party;

  /// Index of the post currently shown; owned by the parent so the action row
  /// and caption follow it.
  final ValueNotifier<int> index;

  /// Mostly on screen, app in foreground, nothing covering the feed.
  final bool active;

  /// Opens the full post viewer; resolves to the index the viewer ended on.
  final Future<int?> Function(int index) onOpenPost;

  final CountdownStyle countdownStyle;

  const PartyMediaCarousel({
    super.key,
    required this.party,
    required this.index,
    required this.active,
    required this.onOpenPost,
    this.countdownStyle = CountdownStyle.overlay,
  });

  @override
  State<PartyMediaCarousel> createState() => _PartyMediaCarouselState();
}

class _PartyMediaCarouselState extends State<PartyMediaCarousel> {
  late final PageController _pages = PageController(initialPage: widget.index.value);
  late final AutoAdvanceController _auto = AutoAdvanceController(onAdvance: _advance);
  bool _detailOpen = false;

  int get _count => widget.party.posts.length;

  @override
  void initState() {
    super.initState();
    _auto.onPostShown(isVideo: _currentIsVideo);
  }

  @override
  void didUpdateWidget(PartyMediaCarousel old) {
    super.didUpdateWidget(old);
    _auto.setActive(_shouldRun);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _auto.setActive(_shouldRun);
    _precacheNeighbours(widget.index.value);
  }

  @override
  void dispose() {
    _auto.dispose();
    _pages.dispose();
    super.dispose();
  }

  // A route covering the feed turns tickers off for it; treat that as inactive too.
  bool get _shouldRun => widget.active && !_detailOpen && TickerMode.valuesOf(context).enabled;

  bool get _currentIsVideo => _count > 0 && widget.party.posts[widget.index.value].isVideo;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _advance() {
    if (!mounted || _count <= 1 || !_pages.hasClients) return;
    final next = (widget.index.value + 1) % _count;
    if (_reduceMotion || next == 0) {
      _pages.jumpToPage(next);
    } else {
      _pages.animateToPage(next, duration: FeedConfig.pageTransition, curve: Curves.easeOutCubic);
    }
  }

  void _onPageChanged(int i) {
    widget.index.value = i;
    _auto.onPostShown(isVideo: widget.party.posts[i].isVideo);
    _precacheNeighbours(i);
  }

  /// Warms the cache for the posts right next to [i] only.
  void _precacheNeighbours(int i) {
    final box = context.findRenderObject() as RenderBox?;
    final width = box != null && box.hasSize ? box.size.width : MediaQuery.sizeOf(context).width;
    final px = requestPixelSize(context, Size(width, width / FeedConfig.mediaAspectRatio));
    for (var d = -FeedConfig.preloadNeighbours; d <= FeedConfig.preloadNeighbours; d++) {
      final j = i + d;
      if (d == 0 || j < 0 || j >= _count) continue;
      final provider = postImageProvider(widget.party.posts[j], px);
      if (provider != null) precacheImage(provider, context, onError: (_, __) {});
    }
  }

  Future<void> _openPost() async {
    setState(() => _detailOpen = true);
    _auto.setActive(false);
    final ended = await widget.onOpenPost(widget.index.value);
    if (!mounted) return;
    setState(() => _detailOpen = false);
    if (ended != null && ended != widget.index.value && _pages.hasClients) _pages.jumpToPage(ended);
    _auto.setActive(_shouldRun);
  }

  @override
  Widget build(BuildContext context) {
    final party = widget.party;
    return AspectRatio(
      aspectRatio: FeedConfig.mediaAspectRatio,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background media — the only layer that slides.
            NotificationListener<ScrollStartNotification>(
              onNotification: (n) {
                if (n.dragDetails != null) _auto.onUserSwipe();
                return false;
              },
              child: PageView.builder(
                controller: _pages,
                itemCount: _count,
                allowImplicitScrolling: true,
                dragStartBehavior: DragStartBehavior.down,
                // Let mouse / trackpad drags swipe too (web on desktop).
                scrollBehavior: ScrollConfiguration.of(context).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
                onPageChanged: _onPageChanged,
                itemBuilder: (context, i) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openPost,
                  child: ValueListenableBuilder<int>(
                    valueListenable: widget.index,
                    builder: (context, current, _) => FeedMediaView(
                      post: party.posts[i],
                      play: i == current && _shouldRun,
                      onVideoCompleted: _auto.onVideoCompleted,
                    ),
                  ),
                ),
              ),
            ),
            // 2. Gentle bottom gradient so white text reads on bright photos.
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.45, 1],
                    colors: [Color(0x00000000), Color(0x8C000000)],
                  ),
                ),
              ),
            ),
            // 3. Party timer — same position and deadline for every post.
            PhotoCountdownOverlay(startAt: party.startAt, endAt: party.endAt, style: widget.countdownStyle, timerStyle: party.timerStyle),
            // 4. Post number.
            Positioned(
              top: 12,
              right: 12,
              child: ValueListenableBuilder<int>(
                valueListenable: widget.index,
                builder: (context, i, _) => _CounterPill(text: '${i + 1} / $_count'),
              ),
            ),
            // 5. Dots and auto-advance toggle.
            if (_count > 1) ...[
              Positioned(
                left: 0,
                right: 0,
                bottom: 14,
                child: Center(
                  child: ValueListenableBuilder<int>(
                    valueListenable: widget.index,
                    builder: (context, i, _) => PageDots(count: _count, index: i),
                  ),
                ),
              ),
              Positioned(
                right: 6,
                bottom: 0,
                child: ListenableBuilder(
                  listenable: _auto,
                  builder: (context, _) => _AutoAdvanceButton(enabled: _auto.enabled, onPressed: _auto.toggle),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CounterPill extends StatelessWidget {
  final String text;
  const _CounterPill({required this.text});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(color: Color(0x73000000), borderRadius: BorderRadius.all(Radius.circular(12))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()])),
        ),
      );
}

class _AutoAdvanceButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  const _AutoAdvanceButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        toggled: enabled,
        label: enabled ? 'Pause auto-advance' : 'Play auto-advance',
        child: InkResponse(
          onTap: onPressed,
          radius: 24,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x33000000),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Icon(enabled ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      );
}
