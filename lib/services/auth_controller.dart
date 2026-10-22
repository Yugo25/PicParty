import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../config/supabase_config.dart';
import 'feed/feed_repository.dart';
import 'people/people_repository.dart';

/// Whether someone is signed in. The router listens to it to show the
/// sign-in screen. In demo mode there are no accounts, so it is always true.
class AuthController extends ChangeNotifier {
  AuthController._();
  static final instance = AuthController._();

  StreamSubscription<AuthState>? _sub;
  String? _userId;

  bool get signedIn => AppConfig.demoMode || _userId != null;

  /// Call once after [SupabaseConfig.init]. The saved session (if any) is
  /// already restored by then.
  void start() {
    if (AppConfig.demoMode || _sub != null) return;
    _userId = SupabaseConfig.client.auth.currentUser?.id;
    _sub = SupabaseConfig.client.auth.onAuthStateChange.listen((state) {
      final id = state.session?.user.id;
      if (id == _userId) return;
      _userId = id;
      // Drop the previous person's cached profile and Parties.
      PeopleRepository.instance.resetCurrentUser();
      FeedRepository.instance.clearCache();
      notifyListeners();
    });
  }
}
