import 'package:flutter/material.dart';
import '../../services/mock_feed_repository.dart';

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
        Row(
          children: [
            for (final t in FeedTab.values)
              Expanded(child: _Tab(label: t == FeedTab.forYou ? 'For you' : 'Following', selected: t == tab, onTap: () => onTab(t))),
          ],
        ),
        const Divider(),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 42,
          child: Stack(
            children: [
              Center(
                child: Text(label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                    )),
              ),
              if (selected)
                Positioned(left: 16, right: 16, bottom: 0, child: Container(height: 2, color: scheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}
