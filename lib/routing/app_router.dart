import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/discover/discover_screen.dart';
import '../screens/activity/activity_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/create_party/create_party_screen.dart';
import '../screens/party/party_screen.dart';
import '../screens/party/feed_party_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/chat/chat_screen.dart';

class AppRouter {
  static final router = GoRouter(initialLocation:'/', routes:[
    ShellRoute(builder:(context,state,child)=>_Shell(child:child),routes:[
      GoRoute(path:'/',builder:(c,s)=>const HomeScreen()),
      GoRoute(path:'/discover',builder:(c,s)=>const DiscoverScreen()),
      GoRoute(path:'/activity',builder:(c,s)=>const ActivityScreen()),
      GoRoute(path:'/profile',builder:(c,s)=>const ProfileScreen()),
    ]),
    GoRoute(path:'/auth',builder:(c,s)=>const AuthScreen()),
    GoRoute(path:'/create',builder:(c,s)=>const CreatePartyScreen()),
    GoRoute(path:'/party/:id',builder:(c,s)=>PartyScreen(partyId:s.pathParameters['id']!)),
    GoRoute(path:'/p/:id',builder:(c,s)=>FeedPartyScreen(partyId:s.pathParameters['id']!)),
    GoRoute(path:'/notifications',builder:(c,s)=>const _NotificationsScreen()),
    GoRoute(path:'/search',builder:(c,s)=>const SearchScreen()),
    GoRoute(path:'/chat/:id',builder:(c,s)=>ChatScreen(conversationId:s.pathParameters['id']!)),
    GoRoute(path:'/settings',builder:(c,s)=>const SettingsScreen()),
  ]);
}

class _NavItem {
  final String label, path;
  final IconData icon, selectedIcon;
  final bool push;
  const _NavItem(this.label, this.path, this.icon, this.selectedIcon, {this.push = false});
}

const _navItems = [
  _NavItem('Home', '/', Icons.home_outlined, Icons.home),
  _NavItem('Explore', '/discover', Icons.explore_outlined, Icons.explore),
  _NavItem('Create', '/create', Icons.add_circle_outline, Icons.add_circle, push: true),
  _NavItem('Inbox', '/activity', Icons.chat_bubble_outline, Icons.chat_bubble),
  _NavItem('Profile', '/profile', Icons.person_outline, Icons.person),
];

/// Bottom navigation: Home / Explore / Create / Inbox / Profile, above the
/// device's safe area so nothing is hidden behind the home indicator.
class _Shell extends StatelessWidget {
  final Widget child;
  const _Shell({required this.child});

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(color: scheme.surface, border: Border(top: BorderSide(color: scheme.outlineVariant, width: 0.5))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                for (final item in _navItems)
                  Expanded(child: _NavButton(item: item, selected: !item.push && item.path == path)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  const _NavButton({required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkResponse(
        onTap: () => item.push ? context.push(item.path) : context.go(item.path),
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? item.selectedIcon : item.icon, color: selected ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.85), size: 26),
              const SizedBox(height: 2),
              Text(item.label, style: TextStyle(fontSize: 11, color: color, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder until notifications exist — says so plainly.
class _NotificationsScreen extends StatelessWidget {
  const _NotificationsScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Notifications aren\'t available in this demo yet.',
                textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ),
      );
}
