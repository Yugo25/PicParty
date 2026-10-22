import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_exception.dart';
import '../../repositories/auth_repository.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/form_parts.dart';
import '../../widgets/common/underline_tabs.dart';
import '../../l10n/l10n.dart';

/// Sign in, or create an account with a name, username, email and password.
/// Shown whenever nobody is signed in; the router moves on once someone is.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _repo = AuthRepository();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signup = false, _busy = false, _showPassword = false;
  String? _nameError, _usernameError, _emailError, _passwordError, _formError, _notice;

  static final _usernamePattern = RegExp(r'^[a-z0-9._]{3,30}$');
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _setMode(bool signup) {
    if (_busy || signup == _signup) return;
    setState(() {
      _signup = signup;
      _nameError = _usernameError = _emailError = _passwordError = _formError = _notice = null;
    });
  }

  /// Checks the fields and shows a message under each wrong one.
  bool _validate() {
    final l = context.l10n;
    final username = _username.text.trim().toLowerCase();
    setState(() {
      _nameError = _signup && _name.text.trim().isEmpty ? l.nameRequired : null;
      _usernameError = _signup && !_usernamePattern.hasMatch(username) ? l.usernameRule : null;
      _emailError = _emailPattern.hasMatch(_email.text.trim()) ? null : l.emailInvalid;
      _passwordError = _password.text.length < (_signup ? 8 : 1) ? l.passwordRule : null;
      _formError = null;
      _notice = null;
    });
    return _nameError == null && _usernameError == null && _emailError == null && _passwordError == null;
  }

  Future<void> _submit() async {
    if (_busy || !_validate()) return;
    setState(() => _busy = true);
    final email = _email.text.trim();
    try {
      if (_signup) {
        final signedIn = await _repo.signUp(
          email: email,
          password: _password.text,
          username: _username.text.trim().toLowerCase(),
          displayName: _name.text.trim(),
        );
        if (!signedIn && mounted) {
          // "Confirm email" is on in Supabase: sign in after opening the link.
          setState(() {
            _signup = false;
            _password.clear();
            _notice = context.l10n.checkEmailToConfirm(email);
          });
          return;
        }
      } else {
        await _repo.signIn(email, _password.text);
      }
      // Lets iPhone offer to save the password. The router then leaves this screen.
      TextInput.finishAutofillContext();
    } on AppException catch (e) {
      if (mounted) _showError(e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String code) {
    final l = context.l10n;
    setState(() {
      switch (code) {
        case 'username_taken':
          _usernameError = l.usernameTaken;
        case 'email_invalid':
          _emailError = l.emailInvalid;
        case 'weak_password':
          _passwordError = l.weakPassword;
        default:
          _formError = switch (code) {
            'wrong_credentials' => l.wrongCredentials,
            'email_taken' => l.emailAlreadyRegistered,
            'confirm_email' => l.confirmEmailFirst,
            'offline' => l.authOffline,
            _ => l.authFailed,
          };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AutofillGroup(
          child: Column(children: [
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(Tokens.gutter, 40, Tokens.gutter, Tokens.gutter),
                children: [
                  Semantics(
                    header: true,
                    child: const Text('图趴 PicParty', style: TextStyle(fontSize: Tokens.pageTitleSize, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 6),
                  Text(l.authTagline, style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 28),
                  UnderlineTabs<bool>(
                    values: const [false, true],
                    selected: _signup,
                    labelOf: (signup) => signup ? l.createAccount : l.signIn,
                    onSelected: _setMode,
                  ),
                  const SizedBox(height: 20),
                  if (_signup) ...[
                    FieldLabel(l.name),
                    TextField(
                      controller: _name,
                      maxLength: 50,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: InputDecoration(errorText: _nameError),
                    ),
                    const SizedBox(height: 6),
                    FieldLabel(l.username),
                    TextField(
                      controller: _username,
                      maxLength: 30,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newUsername],
                      decoration: InputDecoration(prefixText: '@', errorText: _usernameError),
                    ),
                    const SizedBox(height: 6),
                  ],
                  FieldLabel(l.email),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(errorText: _emailError),
                  ),
                  const SizedBox(height: 18),
                  FieldLabel(l.password, trailing: _signup ? l.passwordRule : null),
                  TextField(
                    controller: _password,
                    obscureText: !_showPassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    autofillHints: [_signup ? AutofillHints.newPassword : AutofillHints.password],
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      errorText: _passwordError,
                      suffixIcon: IconButton(
                        tooltip: _showPassword ? l.hidePassword : l.showPassword,
                        icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                  if (_notice != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.mark_email_read_outlined, size: 18, color: scheme.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_notice!, style: TextStyle(color: scheme.onSurfaceVariant))),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
            BottomActionBar(
              above: _formError == null ? null : Padding(padding: const EdgeInsets.only(bottom: 8), child: FieldError(_formError)),
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? (_signup ? l.creatingAccount : l.signingIn) : (_signup ? l.createAccount : l.signIn)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
