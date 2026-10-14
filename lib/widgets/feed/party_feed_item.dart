import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/feed/feed_party.dart';
import '../../screens/media_detail/post_viewer_screen.dart';
import '../../services/feed/active_party_controller.dart';
import '../../services/mock_feed_repository.dart';
import 'comments_sheet.dart';
import 'party_header_row.dart';
import 'party_media_carousel.dart';
import 'party_menu_sheet.dart';
import 'post_action_bar.dart';
import 'post_caption.dart';

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
    if (_party.posts.isEmpty) return const SizedBox.shrink();
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
}
