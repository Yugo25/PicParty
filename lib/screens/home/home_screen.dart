import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/feed/active_party_controller.dart';
import '../../services/feed/feed_repository.dart';
import '../../widgets/feed/feed_header.dart';
import '../../widgets/feed/party_feed_list.dart';

/// Home: header with tabs, then the vertical feed of photo-backed Party timers.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FeedTab _tab = FeedTab.forYou;

  // One controller per tab's list, so the two lists never share keys.
  late ActivePartyController _feed = ActivePartyController();

  @override
  void dispose() {
    _feed.dispose();
    super.dispose();
  }

  void _selectTab(FeedTab tab) {
    if (tab == _tab) return;
    final old = _feed;
    setState(() {
      _tab = tab;
      _feed = ActivePartyController();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          FeedHeader(
            tab: _tab,
            onTab: _selectTab,
            onSearch: () => context.go('/discover?focus=search'),
            onNotifications: () => context.go('/activity?tab=activity'),
          ),
          Expanded(child: PartyFeedList(key: ValueKey(_tab), tab: _tab, feed: _feed)),
        ],
      ),
    );
  }
}
