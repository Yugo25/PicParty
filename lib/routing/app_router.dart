import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/inbox/inbox_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/create_party/create_party_screen.dart';
import '../screens/party/party_screen.dart';
import '../screens/party/feed_party_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../services/auth_controller.dart';
import '../widgets/common/app_bottom_nav.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    refreshListenable: AuthController.instance,
    // Signed out: everything leads to the sign-in screen, which remembers the
    // page that was asked for (a shared Party link) and goes there afterwards.
    redirect: (c, s) {
      final onAuth = s.matchedLocation == '/auth';
      final signedIn = AuthController.instance.signedIn;
      if (!signedIn && !onAuth) return s.uri.path == '/' ? '/auth' : Uri(path: '/auth', queryParameters: {'from': s.uri.toString()}).toString();
      if (signedIn && onAuth) {
        final from = s.uri.queryParameters['from'];
        return from != null && from.startsWith('/') && !from.startsWith('/auth') ? from : '/';
      }
      return null;
    },
    routes: [
      // Tabs with the bottom navigation.
      ShellRoute(
        builder: (context, state, child) => Scaffold(body: child, bottomNavigationBar: AppBottomNav(currentPath: state.uri.path)),
        routes: [
          GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
          GoRoute(path: '/discover', builder: (c, s) => ExploreScreen(focusSearch: s.uri.queryParameters['focus'] == 'search')),
          GoRoute(
            path: '/activity',
            builder: (c, s) => InboxScreen(initialTab: s.uri.queryParameters['tab'] == 'activity' ? InboxTab.activity : InboxTab.messages),
          ),
          GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
        ],
      ),
      // Full-screen flows and detail pages (no bottom navigation).
      GoRoute(path: '/auth', builder: (c, s) => const AuthScreen()),
      GoRoute(path: '/create', builder: (c, s) => const CreatePartyScreen()),
      GoRoute(path: '/party/:id', builder: (c, s) => PartyScreen(partyId: s.pathParameters['id']!)),
      GoRoute(path: '/p/:id', builder: (c, s) => FeedPartyScreen(partyId: s.pathParameters['id']!)),
      GoRoute(path: '/u/:id', builder: (c, s) => ProfileScreen(userId: s.pathParameters['id']!)),
      GoRoute(path: '/profile/edit', builder: (c, s) => const EditProfileScreen()),
      GoRoute(path: '/chat/:id', builder: (c, s) => ChatScreen(conversationId: s.pathParameters['id']!)),
      GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
      // Older links.
      GoRoute(path: '/notifications', redirect: (c, s) => '/activity?tab=activity'),
      GoRoute(path: '/search', redirect: (c, s) => '/discover?focus=search'),
    ],
  );
}
