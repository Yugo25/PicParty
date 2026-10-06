import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/discover/discover_screen.dart';
import '../screens/activity/activity_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/create_party/create_party_screen.dart';
import '../screens/party/party_screen.dart';
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
    GoRoute(path:'/search',builder:(c,s)=>const SearchScreen()),
    GoRoute(path:'/chat/:id',builder:(c,s)=>ChatScreen(conversationId:s.pathParameters['id']!)),
    GoRoute(path:'/settings',builder:(c,s)=>const SettingsScreen()),
  ]);
}
class _Shell extends StatelessWidget { final Widget child; const _Shell({required this.child});
  @override Widget build(BuildContext c)=>Scaffold(body:child,bottomNavigationBar:NavigationBar(selectedIndex:_index(GoRouterState.of(c).uri.path),onDestinationSelected:(i)=>GoRouter.of(c).go(['/','/discover','/activity','/profile'][i]),destinations:const [NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Home'),NavigationDestination(icon:Icon(Icons.explore_outlined),selectedIcon:Icon(Icons.explore),label:'Discover'),NavigationDestination(icon:Icon(Icons.notifications_none),selectedIcon:Icon(Icons.notifications),label:'Activity'),NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person),label:'Profile')]),floatingActionButtonLocation:FloatingActionButtonLocation.centerDocked,floatingActionButton:FloatingActionButton(onPressed:()=>GoRouter.of(c).push('/create'),child:const Icon(Icons.add)));
}
int _index(String p)=>p=='/discover'?1:p=='/activity'?2:p=='/profile'?3:0;
