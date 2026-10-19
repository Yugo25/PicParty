import 'package:flutter/material.dart';
import '../../models/feed/feed_author.dart';
import '../../services/people/people_repository.dart';
import '../../l10n/l10n.dart';

/// Follow / Following toggle for a person. Updates right away and rolls back
/// with a message if the request fails.
class FollowButton extends StatelessWidget {
  final FeedAuthor user;

  /// Stretch to the parent's width (profile header) instead of a compact pill.
  final bool expanded;

  const FollowButton({super.key, required this.user, this.expanded = false});

  Future<void> _toggle(BuildContext context, bool following) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    try {
      await PeopleRepository.instance.setFollowing(user.id, !following);
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(following ? l.unfollowFailed(user.name) : l.followFailed(user.name))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = PeopleRepository.instance;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final following = repo.isFollowing(user.id);
        final size = expanded ? const Size.fromHeight(44) : const Size(96, 36);
        final padding = expanded ? null : const EdgeInsets.symmetric(horizontal: 14);
        return Semantics(
          button: true,
          toggled: following,
          label: following ? context.l10n.followingSemantics(user.name) : context.l10n.followSemantics(user.name),
          child: ExcludeSemantics(
            child: following
                ? OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: size, padding: padding),
                    onPressed: () => _toggle(context, true),
                    child: Text(context.l10n.following),
                  )
                : FilledButton(
                    style: FilledButton.styleFrom(minimumSize: size, padding: padding, textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    onPressed: () => _toggle(context, false),
                    child: Text(context.l10n.follow),
                  ),
          ),
        );
      },
    );
  }
}
