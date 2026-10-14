import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/countdown.dart';
import '../../models/feed/feed_author.dart';
import '../../models/feed/feed_party.dart';
import '../../models/feed/party_options.dart';
import '../../services/explore/explore_repository.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/filters.dart';
import '../../widgets/common/form_parts.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/common/underline_tabs.dart';
import '../../widgets/countdown/phase_builder.dart';
import '../../widgets/feed/author_avatar.dart';
import '../../widgets/feed/party_menu_sheet.dart';
import '../../widgets/party/party_grid_card.dart';
import '../../widgets/people/follow_button.dart';

enum _ExploreTab { parties, people }

/// Explore: search Parties and people. Parties are a 2-column grid of photos
/// with their timers; results load a page at a time.
class ExploreScreen extends StatefulWidget {
  /// Focus the search box on open (from Home's search button).
  final bool focusSearch;
  const ExploreScreen({super.key, this.focusSearch = false});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const _pageSize = 6;
  final _repo = ExploreRepository.instance;
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;

  _ExploreTab _tab = _ExploreTab.parties;
  PartyQuery _query = const PartyQuery();

  final _parties = <FeedParty>[];
  final _people = <FeedAuthor>[];
  int _page = 0;
  bool _loading = false, _failed = false, _hasMore = true;

  /// Incremented on every new search so late responses of an old one are dropped.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _reload();
    if (widget.focusSearch) WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _reload() {
    _generation++;
    setState(() {
      _parties.clear();
      _people.clear();
      _page = 0;
      _hasMore = true;
      _failed = false;
      _loading = false;
    });
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore || _failed) return;
    final gen = _generation;
    setState(() => _loading = true);
    try {
      if (_tab == _ExploreTab.parties) {
        final next = await _repo.parties(_query, page: _page, pageSize: _pageSize);
        if (!mounted || gen != _generation) return;
        setState(() {
          _parties.addAll(next);
          _hasMore = next.length == _pageSize;
        });
      } else {
        final next = await _repo.people(_query.text, page: _page, pageSize: _pageSize * 2);
        if (!mounted || gen != _generation) return;
        setState(() {
          _people.addAll(next);
          _hasMore = next.length == _pageSize * 2;
        });
      }
      _page++;
    } catch (_) {
      if (mounted && gen == _generation) setState(() => _failed = true);
    } finally {
      if (mounted && gen == _generation) setState(() => _loading = false);
    }
  }

  void _retry() {
    setState(() => _failed = false);
    _loadMore();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || text == _query.text) return;
      _query = _query.copyWith(text: text);
      _reload();
    });
  }

  void _setQuery(PartyQuery q) {
    if (q == _query) return;
    _query = q;
    _reload();
  }

  void _setTab(_ExploreTab tab) {
    if (tab == _tab) return;
    _tab = tab;
    _reload();
  }

  void _openParty(FeedParty p) => context.push('/p/${p.id}');

  bool _fitsView(CountdownPhase phase) => switch (_query.view) {
        PartyView.live || PartyView.endingSoon => phase == CountdownPhase.live,
        PartyView.trending || PartyView.newest => phase != CountdownPhase.closed,
        PartyView.everything => true,
      };

  void _drop(FeedParty p) {
    if (mounted && _parties.remove(p)) setState(() {});
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FilterSheet(query: _query, onChanged: _setQuery),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parties = _tab == _ExploreTab.parties;
    final itemCount = parties ? _parties.length : _people.length;

    return SafeArea(
      bottom: false,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Tokens.gutter, 8, 4, 8),
                child: Row(children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text('Explore', style: theme.textTheme.headlineMedium?.copyWith(fontSize: Tokens.pageTitleSize, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  if (parties) IconButton(onPressed: _openFilters, icon: const Icon(Icons.tune), tooltip: 'Sort and filter'),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: Tokens.pagePadding,
                child: AppSearchField(
                  controller: _search,
                  focusNode: _searchFocus,
                  hint: 'Search parties or people',
                  onChanged: _onSearchChanged,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: UnderlineTabs<_ExploreTab>(
                  values: _ExploreTab.values,
                  selected: _tab,
                  labelOf: (t) => t == _ExploreTab.parties ? 'Parties' : 'People',
                  onSelected: _setTab,
                  fontSize: 16,
                ),
              ),
            ),
            if (parties) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(
                child: PillFilters<PartyView>(
                  values: PartyView.values,
                  selected: _query.view,
                  labelOf: (v) => v.label,
                  onSelected: (v) => _setQuery(_query.copyWith(view: v)),
                ),
              ),
              SliverToBoxAdapter(
                child: TextFilters<String?>(
                  values: const [null, ...PartyCategories.ids],
                  selected: _query.category,
                  labelOf: (c) => c == null ? 'All' : PartyCategories.label(c),
                  onSelected: (c) => _setQuery(_query.copyWith(category: c, clearCategory: c == null)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 6)),
            ] else
              const SliverToBoxAdapter(child: SizedBox(height: 4)),
            if (itemCount == 0)
              SliverToBoxAdapter(child: _emptyOrStatus(parties))
            else if (parties)
              SliverPadding(
                padding: Tokens.pagePadding,
                sliver: SliverLayoutBuilder(builder: (context, constraints) {
                  final width = (constraints.crossAxisExtent - Tokens.gridGap) / 2;
                  return SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: Tokens.gridGap,
                      mainAxisSpacing: 14,
                      mainAxisExtent: PartyGridCard.extentFor(context, width),
                    ),
                    itemCount: _parties.length,
                    itemBuilder: (context, i) {
                      if (i >= _parties.length - 2) WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
                      final p = _parties[i];
                      // A card leaves the list as soon as it no longer fits the
                      // view (e.g. a Live Party that just ended).
                      return PhaseBuilder(
                        key: ValueKey(p.id),
                        startAt: p.startAt,
                        endAt: p.endAt,
                        builder: (context, phase) {
                          if (!_fitsView(phase)) WidgetsBinding.instance.addPostFrameCallback((_) => _drop(p));
                          return PartyGridCard(
                            party: p,
                            onTap: () => _openParty(p),
                            onMenu: () => showPartyMenu(context, party: p, onViewParty: () => _openParty(p)),
                          );
                        },
                      );
                    },
                  );
                }),
              )
            else
              SliverList.builder(
                itemCount: _people.length,
                itemBuilder: (context, i) {
                  if (i >= _people.length - 2) WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
                  return _PersonRow(key: ValueKey(_people[i].id), person: _people[i]);
                },
              ),
            if (itemCount > 0) SliverToBoxAdapter(child: PagingFooter(loading: _loading, failed: _failed, onRetry: _retry)),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  Widget _emptyOrStatus(bool parties) {
    if (_failed) return ErrorState(onRetry: _retry);
    if (_loading || _hasMore) return const LoadingState();
    if (!parties) {
      return EmptyState(
        icon: Icons.person_search_outlined,
        title: 'No people found',
        message: _query.text.isEmpty ? null : 'Nobody matches “${_query.text}”.',
      );
    }
    final filtered = _query.category != null || _query.view != PartyView.everything;
    return EmptyState(
      icon: Icons.search_off,
      title: 'No Parties found',
      message: _query.text.isNotEmpty ? 'Nothing matches “${_query.text}” with these filters.' : 'Nothing here right now with these filters.',
      action: filtered
          ? OutlinedButton(onPressed: () => _setQuery(PartyQuery(text: _query.text, view: PartyView.everything)), child: const Text('Show everything'))
          : null,
    );
  }
}

class _PersonRow extends StatelessWidget {
  final FeedAuthor person;
  const _PersonRow({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.push('/u/${person.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter, vertical: 8),
        child: Row(children: [
          AuthorAvatar(author: person, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(person.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(person.handle, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ]),
          ),
          const SizedBox(width: 8),
          FollowButton(user: person),
        ]),
      ),
    );
  }
}

/// Sort and filter, with a sentence explaining each option.
class _FilterSheet extends StatefulWidget {
  final PartyQuery query;
  final ValueChanged<PartyQuery> onChanged;
  const _FilterSheet({required this.query, required this.onChanged});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late PartyQuery _q = widget.query;

  void _set(PartyQuery q) {
    setState(() => _q = q);
    widget.onChanged(q);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Tokens.gutter, 0, Tokens.gutter, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sort & filter', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Text('Show', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            for (final v in PartyView.values)
              Semantics(
                inMutuallyExclusiveGroup: true,
                checked: v == _q.view,
                child: InkWell(
                  onTap: () => _set(_q.copyWith(view: v)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(v.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          Text(v.description, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                        ]),
                      ),
                      Icon(v == _q.view ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: scheme.onSurface),
                    ]),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text('Category', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Pill(label: 'All', selected: _q.category == null, onTap: () => _set(_q.copyWith(clearCategory: true))),
              for (final c in PartyCategories.ids)
                Pill(label: PartyCategories.label(c), selected: _q.category == c, onTap: () => _set(_q.copyWith(category: c))),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              TextButton(onPressed: () => _set(PartyQuery(text: _q.text)), child: const Text('Reset')),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(120, Tokens.controlHeight)),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
