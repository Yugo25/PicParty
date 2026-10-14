import 'package:flutter/material.dart';
import '../../services/mock_feed_repository.dart';
import '../common/underline_tabs.dart';

/// Wordmark, search and notifications, then the For you / Following tabs.
///
/// Tabs switch on tap only — no horizontal swipe — so they never compete with
/// swiping between posts inside a Party.
class FeedHeader extends StatelessWidget {
  final FeedTab tab;
  final ValueChanged<FeedTab> onTab;
  final VoidCallback onSearch, onNotifications;

  const FeedHeader({super.key, required this.tab, required this.onTab, required this.onSearch, required this.onNotifications});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 52,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Semantics(
                header: true,
                child: Text('PicParty', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              ),
              const Spacer(),
              IconButton(onPressed: onSearch, icon: const Icon(Icons.search), tooltip: 'Search'),
              IconButton(onPressed: onNotifications, icon: const Icon(Icons.notifications_none), tooltip: 'Notifications'),
              const SizedBox(width: 4),
            ],
          ),
        ),
        UnderlineTabs<FeedTab>(
          values: FeedTab.values,
          selected: tab,
          labelOf: (t) => t == FeedTab.forYou ? 'For you' : 'Following',
          onSelected: onTab,
          height: 42,
        ),
      ],
    );
  }
}
