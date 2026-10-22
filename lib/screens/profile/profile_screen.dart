import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../models/countdown.dart';
import '../../models/feed/feed_party.dart';
import '../../models/feed/feed_post.dart';
import '../../models/feed/party_options.dart';
import '../../services/inbox/inbox_repository.dart';
import '../../services/mock_feed_repository.dart';
import '../../services/people/people_repository.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/filters.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/common/underline_tabs.dart';
import '../../widgets/feed/author_avatar.dart';
import '../../widgets/feed/party_menu_sheet.dart';
import '../../widgets/party/party_grid_card.dart';
import '../../widgets/party/party_image.dart';
import '../../widgets/people/follow_button.dart';
import '../media_detail/post_viewer_screen.dart';
import '../../widgets/common/app_back_button.dart';
import '../../l10n/l10n.dart';

enum _ProfileTab { parties, posts, memories }

/// A person's Parties, posts and memories. With no [userId] (or the signed-in
/// user's id) it is your own profile, with edit and settings.
class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _people = PeopleRepository.instance;
  final _feed = MockFeedRepository.instance;

  UserProfile? _profile;
  bool _failed = false;
  _ProfileTab _tab = _ProfileTab.parties;
  bool _showCreated = true;

  bool get _own => widget.userId == null || widget.userId == _people.currentUserId;

  @override
  void initState() {
    super.initState();
    _people.addListener(_load);
    _feed.addListener(_changed);
    _load();
  }

  @override
  void dispose() {
    _people.removeListener(_load);
    _feed.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      final p = _own ? await _people.currentProfile() : await _people.profile(widget.userId!);
      if (!mounted) return;
      setState(() {
        _profile = p;
        _failed = p == null;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _retry() {
    setState(() => _failed = false);
    _load();
  }

  Future<void> _shareProfile(UserProfile p) async {
    final messenger = ScaffoldMessenger.of(context);
    final copied = context.l10n.profileLinkCopied;
    await Clipboard.setData(ClipboardData(text: 'https://picparty.app/u/${p.user.username}'));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(copied), duration: const Duration(seconds: 2)));
  }

  Future<void> _message(UserProfile p) async {
    final id = await InboxRepository.instance.conversationWith(p.user);
    if (mounted) context.push('/chat/$id');
  }

  void _openParty(FeedParty party) => context.push('/p/${party.id}');

  void _openPost(FeedPost post) {
    final party = _feed.party(post.partyId);
    if (party == null) return;
    Navigator.of(context, rootNavigator: true).push(PostViewerScreen.route(party: party, initialIndex: party.posts.indexOf(post)));
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final Widget body;
    if (profile == null) {
      body = _failed
          ? Center(child: _own ? ErrorState(onRetry: _retry) : EmptyState(icon: Icons.person_off_outlined, title: context.l10n.profileNotAvailable))
          : const LoadingState();
    } else {
      body = _content(context, profile);
    }
    if (_own) return SafeArea(bottom: false, child: body);
    return Scaffold(appBar: AppBar(leading: const AppBackButton(), title: Text(profile?.user.handle ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))), body: body);
  }

  Widget _content(BuildContext context, UserProfile p) {
    final id = p.user.id;
    final now = DateTime.now();
    bool closed(FeedParty x) => CountdownSnapshot.at(start: x.startAt, end: x.endAt, now: now).phase == CountdownPhase.closed;
    // Others only see what the viewer is allowed to open.
    bool visible(FeedParty x) => _own || x.privacy == PartyPrivacy.public || _feed.canView(x);

    final hosted = _feed.hostedBy(id).where(visible).toList();
    final joined = _feed.joinedBy(id).where(visible).toList();
    int byTime(FeedParty a, FeedParty b) => a.endAt.compareTo(b.endAt);
    final active = (_showCreated ? hosted : joined).where((x) => !closed(x)).toList()..sort(byTime);

    final posts = _feed.postsBy(id).where((post) {
      final party = _feed.party(post.partyId);
      return party != null && visible(party);
    }).toList();

    final memoryIds = <String>{};
    final memories = [
      ...hosted,
      ...joined,
      for (final post in posts)
        if (_feed.party(post.partyId) case final party?) party,
    ].where((x) => closed(x) && memoryIds.add(x.id)).toList()
      ..sort((a, b) => b.endAt.compareTo(a.endAt));

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _Header(profile: p, own: _own, partyCount: hosted.length + joined.length, onShare: () => _shareProfile(p), onMessage: () => _message(p))),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: UnderlineTabs<_ProfileTab>(
              values: _ProfileTab.values,
              selected: _tab,
              labelOf: (t) => switch (t) {
                _ProfileTab.parties => context.l10n.parties,
                _ProfileTab.posts => context.l10n.posts,
                _ProfileTab.memories => context.l10n.memories,
              },
              onSelected: (t) => setState(() => _tab = t),
              fontSize: 16,
            ),
          ),
        ),
        ...switch (_tab) {
          _ProfileTab.parties => _partiesTab(context, active, memories),
          _ProfileTab.posts => _postsTab(posts),
          _ProfileTab.memories => _memoriesTab(context, memories),
        },
        SliverToBoxAdapter(child: SizedBox(height: 24 + (_own ? 0 : MediaQuery.paddingOf(context).bottom))),
      ]),
    );
  }

  List<Widget> _partiesTab(BuildContext context, List<FeedParty> active, List<FeedParty> memories) {
    final theme = Theme.of(context);
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: PillFilters<bool>(
            values: const [true, false],
            selected: _showCreated,
            labelOf: (created) => created ? context.l10n.created : context.l10n.joined,
            onSelected: (created) => setState(() => _showCreated = created),
          ),
        ),
      ),
      if (active.isEmpty)
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.celebration_outlined,
            title: context.l10n.noLiveParties,
            message: _showCreated
                ? (_own ? context.l10n.partiesYouHost : null)
                : (_own ? context.l10n.partiesYouJoin : null),
            action: _own && _showCreated ? FilledButton(onPressed: () => context.push('/create'), child: Text(context.l10n.createAParty)) : null,
          ),
        )
      else
        _grid(
          context,
          itemCount: active.length,
          extent: PartyGridCard.extentFor,
          builder: (i) => PartyGridCard(
            key: ValueKey(active[i].id),
            party: active[i],
            onTap: () => _openParty(active[i]),
            onMenu: () => showPartyMenu(context, party: active[i], onViewParty: () => _openParty(active[i])),
          ),
        ),
      if (memories.isNotEmpty) ...[
        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(Tokens.gutter, 20, Tokens.gutter, 0), child: Divider())),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Tokens.gutter, 8, 4, 4),
            child: Row(children: [
              Expanded(child: Semantics(header: true, child: Text(context.l10n.recentMemories, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)))),
              TextButton(
                onPressed: () => setState(() => _tab = _ProfileTab.memories),
                child: Row(mainAxisSize: MainAxisSize.min, children: [Text(context.l10n.seeAll), const Icon(Icons.chevron_right, size: 20)]),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: Tokens.pagePadding,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < 2; i++) ...[
                if (i > 0) const SizedBox(width: Tokens.gridGap),
                Expanded(
                  child: i < memories.length
                      ? MemoryCard(party: memories[i], aspectRatio: 2.2, onTap: () => _openParty(memories[i]))
                      : const SizedBox.shrink(),
                ),
              ],
            ]),
          ),
        ),
      ],
    ];
  }

  List<Widget> _postsTab(List<FeedPost> posts) {
    if (posts.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.photo_library_outlined,
            title: context.l10n.noPostsYet,
            message: _own ? context.l10n.postsYouAdd : null,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.only(top: 2),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 2),
          itemCount: posts.length,
          itemBuilder: (context, i) => Semantics(
            button: true,
            label: context.l10n.postOf(i + 1, posts.length),
            child: GestureDetector(onTap: () => _openPost(posts[i]), child: PostThumbnail(post: posts[i])),
          ),
        ),
      ),
    ];
  }

  List<Widget> _memoriesTab(BuildContext context, List<FeedParty> memories) {
    if (memories.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EmptyState(icon: Icons.auto_awesome_outlined, title: context.l10n.noMemories, message: context.l10n.noMemoriesMessage),
        ),
      ];
    }
    return [
      const SliverToBoxAdapter(child: SizedBox(height: 14)),
      _grid(
        context,
        itemCount: memories.length,
        extent: MemoryCard.extentFor,
        builder: (i) => MemoryCard(key: ValueKey(memories[i].id), party: memories[i], onTap: () => _openParty(memories[i])),
      ),
    ];
  }

  Widget _grid(BuildContext context,
      {required int itemCount, required double Function(BuildContext, double) extent, required Widget Function(int i) builder}) {
    return SliverPadding(
      padding: Tokens.pagePadding,
      sliver: SliverLayoutBuilder(builder: (context, constraints) {
        final width = (constraints.crossAxisExtent - Tokens.gridGap) / 2;
        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: Tokens.gridGap,
            mainAxisSpacing: 14,
            mainAxisExtent: extent(context, width),
          ),
          itemCount: itemCount,
          itemBuilder: (context, i) => builder(i),
        );
      }),
    );
  }
}

class _Header extends StatelessWidget {
  final UserProfile profile;
  final bool own;
  final int partyCount;
  final VoidCallback onShare, onMessage;
  const _Header({required this.profile, required this.own, required this.partyCount, required this.onShare, required this.onMessage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = profile.user;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Tokens.gutter, 12, Tokens.gutter, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AuthorAvatar(author: user, size: 88),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.name, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700)),
                Text(user.handle, style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant)),
                if (profile.bio?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(profile.bio!, style: const TextStyle(fontSize: 15)),
                ],
              ]),
            ),
          ),
          if (own) ...[
            IconButton(onPressed: onShare, icon: const Icon(Icons.ios_share), tooltip: context.l10n.shareProfile),
            IconButton(onPressed: () => context.push('/settings'), icon: const Icon(Icons.settings_outlined), tooltip: context.l10n.settings),
          ],
        ]),
        const SizedBox(height: 18),
        IntrinsicHeight(
          child: Row(children: [
            Expanded(child: _Stat(value: partyCount, label: context.l10n.parties)),
            VerticalDivider(color: scheme.outlineVariant, width: 1, indent: 6, endIndent: 6),
            Expanded(child: _Stat(value: profile.followers, label: context.l10n.followers)),
            VerticalDivider(color: scheme.outlineVariant, width: 1, indent: 6, endIndent: 6),
            Expanded(child: _Stat(value: profile.following, label: context.l10n.statFollowing)),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: own
            ? [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                    onPressed: () => context.push('/profile/edit'),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: Text(context.l10n.editProfile),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share, size: 20),
                    label: Text(context.l10n.shareProfile),
                  ),
                ),
              ]
            : [
                Expanded(child: FollowButton(user: user, expanded: true)),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                    onPressed: onMessage,
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: Text(context.l10n.message),
                  ),
                ),
              ]),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$value $label',
        child: ExcludeSemantics(
          child: Column(children: [
            Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
            Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ),
      );
}
