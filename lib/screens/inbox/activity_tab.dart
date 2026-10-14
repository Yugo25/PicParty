import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/time_format.dart';
import '../../models/countdown.dart';
import '../../models/feed/feed_party.dart';
import '../../models/feed/feed_post.dart';
import '../../models/inbox/inbox_models.dart';
import '../../services/inbox/inbox_repository.dart';
import '../../services/mock_feed_repository.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/filters.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/countdown/phase_builder.dart';
import '../../widgets/feed/author_avatar.dart';
import '../../widgets/party/party_image.dart';
import '../../widgets/people/follow_button.dart';
import '../media_detail/post_viewer_screen.dart';

/// Invites, likes, comments, follows and Party reminders, grouped by day.
class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  final _repo = InboxRepository.instance;
  ActivityFilter _filter = ActivityFilter.all;
  List<ActivityItem>? _items;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_changed);
    _load();
  }

  @override
  void dispose() {
    _repo.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _items = null;
      _failed = false;
    });
    final filter = _filter;
    try {
      final items = await _repo.activity(filter);
      if (mounted && filter == _filter) setState(() => _items = items);
    } catch (_) {
      if (mounted && filter == _filter) setState(() => _failed = true);
    }
  }

  void _setFilter(ActivityFilter f) {
    if (f == _filter) return;
    _filter = f;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final now = DateTime.now();
    final today = items?.where((a) => TimeFormat.isToday(a.createdAt, now)).toList() ?? const <ActivityItem>[];
    final earlier = items?.where((a) => !TimeFormat.isToday(a.createdAt, now)).toList() ?? const <ActivityItem>[];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: PillFilters<ActivityFilter>(
          values: ActivityFilter.values,
          selected: _filter,
          labelOf: (f) => f.label,
          onSelected: _setFilter,
          expand: true,
        ),
      ),
      Expanded(
        child: _failed
            ? Center(child: SingleChildScrollView(child: ErrorState(onRetry: _load)))
            : items == null
                ? const LoadingState()
                : items.isEmpty
                    ? Center(child: SingleChildScrollView(child: _empty()))
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 16),
                        children: [
                          if (today.isNotEmpty) ...[const _SectionTitle('Today'), for (final a in today) _ActivityRow(item: a)],
                          if (earlier.isNotEmpty) ...[const _SectionTitle('Earlier'), for (final a in earlier) _ActivityRow(item: a)],
                        ],
                      ),
      ),
    ]);
  }

  Widget _empty() => switch (_filter) {
        ActivityFilter.all => const EmptyState(icon: Icons.notifications_none, title: 'No activity yet', message: 'Likes, comments, follows and invites will show up here.'),
        ActivityFilter.invites => const EmptyState(icon: Icons.mail_outline, title: 'No invites', message: 'When someone invites you to a Party, it shows up here.'),
        ActivityFilter.interactions =>
          const EmptyState(icon: Icons.favorite_border, title: 'No interactions yet', message: 'Likes, comments and new followers will show up here.'),
      };
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Tokens.gutter, 14, Tokens.gutter, 4),
        child: Semantics(header: true, child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      );
}

class _ActivityRow extends StatelessWidget {
  final ActivityItem item;
  const _ActivityRow({required this.item});

  FeedParty? get _party => item.partyId == null ? null : MockFeedRepository.instance.party(item.partyId!);

  FeedPost? _post(FeedParty? party) {
    if (party == null || item.postId == null) return null;
    for (final p in party.posts) {
      if (p.id == item.postId) return p;
    }
    return null;
  }

  void _openPost(BuildContext context, FeedParty party, FeedPost post) =>
      Navigator.of(context, rootNavigator: true).push(PostViewerScreen.route(party: party, initialIndex: party.posts.indexOf(post)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final party = _party;
    final post = _post(party);
    final actor = item.actor;
    final bold = TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface);
    final base = TextStyle(fontSize: 15, height: 1.3, color: scheme.onSurface);
    final time = Text(TimeFormat.ago(item.createdAt, DateTime.now()), style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant));

    Widget leading = actor != null
        ? GestureDetector(onTap: () => context.push('/u/${actor.id}'), child: AuthorAvatar(author: actor, size: 44))
        : Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: scheme.outlineVariant)),
            child: const Icon(Icons.schedule, size: 22, semanticLabel: 'Reminder'),
          );

    Widget thumb(Widget child, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: ClipRRect(borderRadius: BorderRadius.circular(Tokens.radiusSmall), child: SizedBox(width: 56, height: 56, child: child)),
        );

    Widget? trailing;
    Widget text;
    Widget? below;
    VoidCallback? onTap;

    switch (item.kind) {
      case ActivityKind.invite:
        text = Text.rich(TextSpan(style: base, children: [
          TextSpan(text: actor?.name ?? 'Someone', style: bold),
          const TextSpan(text: ' invited you to '),
          TextSpan(text: party?.title ?? 'a Party', style: bold),
        ]));
        trailing = time;
        if (party != null) below = _InviteBody(item: item, party: party);
      case ActivityKind.like:
        text = Text.rich(TextSpan(style: base, children: [
          TextSpan(text: actor?.name ?? 'Someone', style: bold),
          TextSpan(text: post?.isVideo == true ? ' liked your video' : ' liked your photo'),
        ]));
        if (party != null && post != null) {
          onTap = () => _openPost(context, party, post);
          trailing = thumb(PostImage(post: post), onTap);
        }
      case ActivityKind.comment:
        text = Text.rich(TextSpan(style: base, children: [
          TextSpan(text: actor?.name ?? 'Someone', style: bold),
          const TextSpan(text: ' commented: '),
          TextSpan(text: '“${item.comment ?? ''}”'),
        ]));
        if (party != null && post != null) {
          onTap = () => _openPost(context, party, post);
          trailing = thumb(PostImage(post: post), onTap);
        }
      case ActivityKind.follow:
        text = Text.rich(TextSpan(style: base, children: [
          TextSpan(text: actor?.name ?? 'Someone', style: bold),
          const TextSpan(text: ' started following you'),
        ]));
        if (actor != null) {
          trailing = FollowButton(user: actor);
          onTap = () => context.push('/u/${actor.id}');
        }
      case ActivityKind.reminder:
        // Worded from the Party's state now, never from when it was sent.
        text = party == null
            ? Text('A Party you joined has changed', style: base)
            : PhaseBuilder(
                startAt: party.startAt,
                endAt: party.endAt,
                builder: (context, phase) {
                  final now = DateTime.now();
                  final rest = switch (phase) {
                    CountdownPhase.upcoming => ' starts ${TimeFormat.dayAndTime(party.startAt, now)}',
                    CountdownPhase.live => ' closes ${TimeFormat.dayAndTime(party.endAt, now)}',
                    CountdownPhase.closed => ' has ended. Uploads are closed.',
                  };
                  return Text.rich(TextSpan(style: base, children: [TextSpan(text: party.title, style: bold), TextSpan(text: rest)]));
                },
              );
        if (party != null) {
          onTap = () => context.push('/p/${party.id}');
          trailing = thumb(PartyImage(party: party), onTap);
        }
    }

    final showTimeUnderText = item.kind != ActivityKind.invite;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter, vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                text,
                if (showTimeUnderText) ...[const SizedBox(height: 2), time],
              ]),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing],
          ]),
          if (below != null) Padding(padding: const EdgeInsets.only(left: 56, top: 10), child: below),
        ]),
      ),
    );
  }
}

/// Party cover plus Accept / Decline, replaced by the outcome once answered.
class _InviteBody extends StatefulWidget {
  final ActivityItem item;
  final FeedParty party;
  const _InviteBody({required this.item, required this.party});

  @override
  State<_InviteBody> createState() => _InviteBodyState();
}

class _InviteBodyState extends State<_InviteBody> {
  bool _busy = false;

  Future<void> _respond(bool accept) async {
    setState(() => _busy = true);
    try {
      await InboxRepository.instance.respondToInvite(widget.item, accept: accept);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Couldn\'t send your answer. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final party = widget.party;
    final status = widget.item.inviteStatus;
    final muted = TextStyle(fontSize: 14, color: scheme.onSurfaceVariant);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GestureDetector(
        onTap: () => context.push('/p/${party.id}'),
        child: AspectRatio(
          aspectRatio: 2.4,
          child: ClipRRect(borderRadius: BorderRadius.circular(Tokens.radius), child: PartyImage(party: party)),
        ),
      ),
      const SizedBox(height: 10),
      PhaseBuilder(
        startAt: party.startAt,
        endAt: party.endAt,
        builder: (context, phase) {
          if (status == InviteStatus.accepted) {
            return Row(children: [
              const Icon(Icons.check_circle_outline, size: 20),
              const SizedBox(width: 6),
              const Expanded(child: Text('You joined this Party', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
              TextButton(onPressed: () => context.push('/p/${party.id}'), child: const Text('View Party')),
            ]);
          }
          if (status == InviteStatus.declined) return Text('Invite declined', style: muted);
          if (phase == CountdownPhase.closed) return Text('This Party has ended', style: muted);
          return Row(children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                onPressed: _busy ? null : () => _respond(true),
                child: const Text('Accept'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                onPressed: _busy ? null : () => _respond(false),
                child: const Text('Decline'),
              ),
            ),
          ]);
        },
      ),
    ]);
  }
}
