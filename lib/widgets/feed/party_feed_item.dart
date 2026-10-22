import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/feed_config.dart';
import '../../models/feed/feed_party.dart';
import '../../screens/media_detail/post_viewer_screen.dart';
import '../../services/feed/active_party_controller.dart';
import '../../services/mock_feed_repository.dart';
import '../countdown/photo_countdown_overlay.dart';
import '../party/party_image.dart';
import 'comments_sheet.dart';
import 'party_header_row.dart';
import 'party_media_carousel.dart';
import 'party_menu_sheet.dart';
import 'post_action_bar.dart';
import 'post_caption.dart';
import '../../l10n/l10n.dart';

/// One Party in the home feed:
/// header → photo-backed countdown → post actions → caption → divider.
///
/// The Party name, deadline and timer stay put; swiping the photo changes only
/// the post-specific parts (author, reactions, caption, post number).
class PartyFeedItem extends StatefulWidget {
  final FeedParty party;
  final ActivePartyController feed;
  const PartyFeedItem({super.key, required this.party, required this.feed});

  @override
  State<PartyFeedItem> createState() => _PartyFeedItemState();
}

class _PartyFeedItemState extends State<PartyFeedItem> {
  final _index = ValueNotifier<int>(0);
  final _repo = MockFeedRepository.instance;

  FeedParty get _party => widget.party;

  @override
  void dispose() {
    widget.feed.unregister(_party.id);
    _index.dispose();
    super.dispose();
  }

  void _openParty() => widget.feed.suspendWhile(context.push('/p/${_party.id}'));

  Future<int?> _openPost(int index) => widget.feed.suspendWhile(
        Navigator.of(context, rootNavigator: true).push<int>(PostViewerScreen.route(party: _party, initialIndex: index)),
      );

  @override
  Widget build(BuildContext context) {
    if (_party.posts.isEmpty) return _coverOnly(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PartyHeaderRow(
          party: _party,
          onOpenParty: _openParty,
          onMenu: () => widget.feed.suspendWhile(showPartyMenu(context, party: _party, onViewParty: _openParty)),
        ),
        KeyedSubtree(
          key: widget.feed.keyFor(_party.id),
          child: ListenableBuilder(
            listenable: Listenable.merge([widget.feed.activeId, widget.feed.suspended]),
            builder: (context, _) => PartyMediaCarousel(
              party: _party,
              index: _index,
              active: widget.feed.activeId.value == _party.id && !widget.feed.suspended.value,
              onOpenPost: _openPost,
            ),
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: _index,
          builder: (context, i, _) {
            final post = _party.posts[i];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PostActionBar(
                  post: post,
                  onLike: () => _repo.toggleLike(post),
                  onComments: () => widget.feed.suspendWhile(showCommentsSheet(context, post)),
                  onShare: () => copyPartyLink(context, _party),
                ),
                PostCaption(post: post, onViewParty: _openParty),
              ],
            );
          },
        ),
        const Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 0), child: Divider()),
      ],
    );
  }

  /// Before anyone has posted, the cover stands in as the timer's background.
  Widget _coverOnly(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PartyHeaderRow(
          party: _party,
          onOpenParty: _openParty,
          onMenu: () => widget.feed.suspendWhile(showPartyMenu(context, party: _party, onViewParty: _openParty)),
        ),
        GestureDetector(
          onTap: _openParty,
          child: AspectRatio(
            aspectRatio: FeedConfig.mediaAspectRatio,
            child: ClipRect(
              child: Stack(fit: StackFit.expand, children: [
                PartyImage(party: _party, coverOnly: true),
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.45, 1], colors: [Color(0x00000000), Color(0x8C000000)]),
                    ),
                  ),
                ),
                PhotoCountdownOverlay(startAt: _party.startAt, endAt: _party.endAt, timerStyle: _party.timerStyle),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(context.l10n.feedNoPosts,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, color: theme.colorScheme.onSurfaceVariant)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Align(alignment: Alignment.centerLeft, child: ViewPartyLink(onTap: _openParty)),
        ),
        const Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 0), child: Divider()),
      ],
    );
  }
}
