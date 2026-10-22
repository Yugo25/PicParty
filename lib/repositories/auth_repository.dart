import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../config/supabase_config.dart';
import '../core/app_exception.dart';

/// Sign up, sign in and sign out. Failures are thrown as [AppException]s
/// whose code the sign-in screen turns into a message:
/// `username_taken`, `email_taken`, `wrong_credentials`, `weak_password`,
/// `email_invalid`, `confirm_email`, `offline` or `auth_failed`.
class AuthRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  /// The signed-in email, or null in demo mode or when signed out.
  String? get email => AppConfig.demoMode ? null : _client.auth.currentUser?.email;

  Future<void> signIn(String email, String password) async {
    if (AppConfig.demoMode) return;
    await _guard(() => _client.auth.signInWithPassword(email: email, password: password));
  }

  /// Creates the account. Returns false when Supabase still needs the email
  /// to be confirmed before the person can sign in ("Confirm email" is on).
  Future<bool> signUp({required String email, required String password, required String username, required String displayName}) async {
    if (AppConfig.demoMode) return true;
    final available = await _guard(() => _client.rpc('username_available', params: {'p_username': username}));
    if (available == false) throw const AppException('username_taken', 'That username is taken.');
    final res = await _guard(() => _client.auth.signUp(
          email: email,
          password: password,
          data: {'user_name': username, 'display_name': displayName},
        ));
    return res.session != null;
  }

  Future<void> signOut() async {
    if (!AppConfig.demoMode) await _client.auth.signOut();
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on AuthRetryableFetchException {
      throw const AppException('offline', 'Couldn\'t connect. Check your connection and try again.');
    } on AuthException catch (e) {
      throw switch (e.code) {
        'invalid_credentials' => AppException('wrong_credentials', e.message),
        'email_not_confirmed' => AppException('confirm_email', e.message),
        'user_already_exists' || 'email_exists' => AppException('email_taken', e.message),
        'weak_password' => AppException('weak_password', e.message),
        'email_address_invalid' || 'validation_failed' => AppException('email_invalid', e.message),
        _ => AppException('auth_failed', e.message),
      };
    } on PostgrestException catch (e) {
      throw AppException('auth_failed', e.message);
    } on AppException {
      rethrow;
    } catch (_) {
      // Anything else (no connection, DNS, timeouts) comes from the HTTP client.
      throw const AppException('offline', 'Couldn\'t connect. Check your connection and try again.');
    }
  }
}
