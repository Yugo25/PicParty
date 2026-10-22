import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../models/feed/feed_party.dart';
import '../../widgets/feed/author_avatar.dart';
import '../../widgets/feed/feed_media_view.dart';
import '../../l10n/l10n.dart';

/// Full-screen view of a Party's posts: the whole photo (not cropped), zoomable,
/// swipeable. Pops with the index it ended on so the feed can follow.
class PostViewerScreen extends StatefulWidget {
  final FeedParty party;
  final int initialIndex;
  const PostViewerScreen({super.key, required this.party, required this.initialIndex});

  static Route<int> route({required FeedParty party, required int initialIndex}) => MaterialPageRoute<int>(
        fullscreenDialog: true,
        builder: (_) => PostViewerScreen(party: party, initialIndex: initialIndex),
      );

  @override
  State<PostViewerScreen> createState() => _PostViewerScreenState();
}

class _PostViewerScreenState extends State<PostViewerScreen> {
  late final _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = widget.party.posts;
    final post = posts[_index];
    return PopScope<int>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_index);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(icon: const Icon(Icons.close), tooltip: context.l10n.close, onPressed: () => Navigator.of(context).pop(_index)),
          title: Text(widget.party.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          actions: [
            Center(child: Text('${_index + 1} / ${posts.length}', style: const TextStyle(color: Colors.white70))),
            const SizedBox(width: 16),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: posts.length,
                scrollBehavior: ScrollConfiguration.of(context).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => InteractiveViewer(
                  maxScale: 4,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: FeedMediaView(post: posts[i], play: i == _index, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    AuthorAvatar(author: post.author),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.author.handle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          if (post.caption != null) Text(post.caption!, style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
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
