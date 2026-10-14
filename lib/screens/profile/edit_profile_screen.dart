import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_config.dart';
import '../../services/people/people_repository.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/form_parts.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/common/app_back_button.dart';

/// Edit name, username and bio.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _repo = PeopleRepository.instance;
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  bool _loaded = false, _saving = false;
  String? _usernameError, _saveError;

  static final _usernamePattern = RegExp(r'^[a-z0-9._]{3,30}$');

  @override
  void initState() {
    super.initState();
    _repo.currentProfile().then((p) {
      if (!mounted) return;
      setState(() {
        _name.text = p.user.displayName ?? '';
        _username.text = p.user.username;
        _bio.text = p.bio ?? '';
        _loaded = true;
      });
    }, onError: (_) {
      if (mounted) setState(() => _saveError = 'Couldn\'t load your profile.');
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final username = _username.text.trim().toLowerCase();
    final error = _usernamePattern.hasMatch(username) ? null : 'Use 3–30 lowercase letters, numbers, dots or underscores.';
    setState(() {
      _usernameError = error;
      _saveError = null;
    });
    if (error != null) return;
    setState(() => _saving = true);
    try {
      await _repo.updateProfile(displayName: _name.text.trim(), username: username, bio: _bio.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppConfig.demoMode ? 'Saved for this session (demo)' : 'Profile updated')),
      );
      context.pop();
    } catch (_) {
      if (mounted) setState(() => _saveError = 'Couldn\'t save. Your changes are still here — try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), centerTitle: true, title: const Text('Edit profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
      body: !_loaded
          ? (_saveError != null ? Center(child: Text(_saveError!)) : const LoadingState())
          : Column(children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(Tokens.gutter),
                  children: [
                    const FieldLabel('Name'),
                    TextField(controller: _name, maxLength: 50, textCapitalization: TextCapitalization.words),
                    const SizedBox(height: 6),
                    const FieldLabel('Username'),
                    TextField(
                      controller: _username,
                      maxLength: 30,
                      autocorrect: false,
                      decoration: InputDecoration(prefixText: '@', errorText: _usernameError),
                    ),
                    const SizedBox(height: 6),
                    const FieldLabel('Bio', trailing: 'Optional'),
                    TextField(controller: _bio, maxLength: 150, minLines: 2, maxLines: 4, textCapitalization: TextCapitalization.sentences),
                  ],
                ),
              ),
              BottomActionBar(
                above: _saveError == null ? null : Padding(padding: const EdgeInsets.only(bottom: 8), child: FieldError(_saveError)),
                child: FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save')),
              ),
            ]),
    );
  }
}
