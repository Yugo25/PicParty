import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/feed_config.dart';
import '../../models/countdown.dart';
import '../../models/feed/feed_party.dart';
import '../../services/mock_feed_repository.dart';
import '../../widgets/countdown/countdown_style.dart';
import '../../widgets/countdown/phase_builder.dart';
import '../../widgets/countdown/photo_countdown_overlay.dart';
import '../../widgets/feed/feed_media_view.dart';
import '../../widgets/feed/party_menu_sheet.dart';
import '../media_detail/post_viewer_screen.dart';

/// "View Party": the Party's timer, upload button and all of its posts.
/// Posts stay viewable after the deadline; uploads are only possible while live.
class FeedPartyScreen extends StatefulWidget {
  final String partyId;
  const FeedPartyScreen({super.key, required this.partyId});

  @override
  State<FeedPartyScreen> createState() => _FeedPartyScreenState();
}

class _FeedPartyScreenState extends State<FeedPartyScreen> {
  final _repo = MockFeedRepository.instance;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_changed);
  }

  @override
  void dispose() {
    _repo.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _upload(FeedParty party) async {
    final x = await ImagePicker().pickMedia();
    if (x == null || !mounted) return;
    // Re-check: the deadline may have passed while the picker was open.
    final now = DateTime.now();
    if (!CountdownSnapshot.at(start: party.startAt, end: party.endAt, now: now).acceptsUploads) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploads for this Party are closed')));
      return;
    }
    final video = (x.mimeType ?? '').startsWith('video/') || RegExp(r'\.(mp4|mov|m4v|webm)$', caseSensitive: false).hasMatch(x.name);
    _repo.addLocalPost(party, path: x.path, video: video);
  }

  @override
  Widget build(BuildContext context) {
    final party = _repo.party(widget.partyId);
    if (party == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Party no longer available')));
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final thumbPx = requestPixelSize(context, Size.square(width / 3));

    return Scaffold(
      appBar: AppBar(
        title: Text(party.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [IconButton(onPressed: () => copyPartyLink(context, party), icon: const Icon(Icons.ios_share), tooltip: 'Copy link')],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AspectRatio(
              aspectRatio: FeedConfig.mediaAspectRatio,
              child: Stack(fit: StackFit.expand, children: [
                if (party.posts.isNotEmpty) FeedMediaView(post: party.posts.first),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.45, 1], colors: [Color(0x00000000), Color(0x8C000000)]),
                  ),
                ),
                PhotoCountdownOverlay(startAt: party.startAt, endAt: party.endAt, style: CountdownStyle.compact),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('${party.contributorCount} contributors · ${party.posts.length} posts',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  PhaseBuilder(
                    startAt: party.startAt,
                    endAt: party.endAt,
                    builder: (context, phase) => _UploadButton(
                      phase: phase,
                      opensAt: CountdownSnapshot.formatMoment(party.startAt, DateTime.now()),
                      onPressed: () => _upload(party),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 2),
            itemCount: party.posts.length,
            itemBuilder: (context, i) {
              final post = party.posts[i];
              final url = post.imageUrl?.call(thumbPx.width.toInt(), thumbPx.height.toInt());
              return GestureDetector(
                onTap: () => Navigator.of(context).push(PostViewerScreen.route(party: party, initialIndex: i)),
                child: Stack(fit: StackFit.expand, children: [
                  url != null
                      ? Image.network(url,
                          fit: BoxFit.cover,
                          cacheWidth: thumbPx.width.toInt(),
                          frameBuilder: (context, child, frame, wasSync) => wasSync || frame != null ? child : const MediaPlaceholder(),
                          errorBuilder: (context, error, stack) => const MediaPlaceholder(error: true))
                      : FeedMediaView(post: post),
                  if (post.isVideo) const Positioned(top: 6, right: 6, child: Icon(Icons.videocam_outlined, color: Colors.white, size: 18)),
                ]),
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom)),
        ],
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  final CountdownPhase phase;
  final String opensAt;
  final VoidCallback onPressed;
  const _UploadButton({required this.phase, required this.opensAt, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(minimumSize: const Size.fromHeight(48));
    return switch (phase) {
      CountdownPhase.live => FilledButton.icon(
          style: style, onPressed: onPressed, icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('Add photo / video')),
      CountdownPhase.upcoming =>
        FilledButton.icon(style: style, onPressed: null, icon: const Icon(Icons.schedule), label: Text('Uploads open $opensAt')),
      CountdownPhase.closed =>
        FilledButton.icon(style: style, onPressed: null, icon: const Icon(Icons.lock_outline), label: const Text('Uploads closed')),
    };
  }
}
