import 'package:flutter/material.dart';
import '../../config/feed_config.dart';
import '../../models/feed/feed_party.dart';
import '../../services/feed/active_party_controller.dart';
import '../../services/mock_feed_repository.dart';
import 'party_feed_item.dart';

/// Vertically scrolling, lazily built and paged list of Parties.
class PartyFeedList extends StatefulWidget {
  final FeedTab tab;
  final ActivePartyController feed;
  const PartyFeedList({super.key, required this.tab, required this.feed});

  @override
  State<PartyFeedList> createState() => _PartyFeedListState();
}

class _PartyFeedListState extends State<PartyFeedList> {
  final _repo = MockFeedRepository.instance;
  final _parties = <FeedParty>[];
  int _page = 0;
  bool _loading = false, _hasMore = true, _failed = false;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final next = await _repo.fetchParties(tab: widget.tab, page: _page, pageSize: FeedConfig.feedPageSize);
      if (!mounted) return;
      setState(() {
        _parties.addAll(next);
        _page++;
        _hasMore = next.length == FeedConfig.feedPageSize;
      });
      _scheduleRecompute();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scheduleRecompute() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.feed.recompute();
      });

  @override
  Widget build(BuildContext context) {
    if (_parties.isEmpty && _loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (_parties.isEmpty && !_hasMore) {
      return Center(child: Text('Nothing here yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        // Vertical feed scrolling only; the media PageViews also bubble
        // horizontal notifications up here.
        if (n.metrics.axis == Axis.vertical) widget.feed.recompute();
        return false;
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.builder(
          key: widget.feed.viewportKey,
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: _parties.length + 1,
          itemBuilder: (context, i) {
            if (i >= _parties.length - 1) WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
            if (i == _parties.length) return _Footer(loading: _loading, failed: _failed, hasMore: _hasMore, onRetry: _loadMore);
            return PartyFeedItem(key: ValueKey(_parties[i].id), party: _parties[i], feed: widget.feed);
          },
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final bool loading, failed, hasMore;
  final VoidCallback onRetry;
  const _Footer({required this.loading, required this.failed, required this.hasMore, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return SizedBox(
      height: 72,
      child: Center(
        child: failed
            ? TextButton(onPressed: onRetry, child: const Text('Couldn\'t load more. Retry'))
            : loading || hasMore
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('You\'re all caught up', style: muted),
      ),
    );
  }
}
