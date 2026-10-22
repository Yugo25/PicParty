import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_config.dart';
import '../../models/feed/feed_author.dart';
import '../../services/people/people_repository.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/form_parts.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/feed/author_avatar.dart';
import '../../l10n/l10n.dart';

/// Edit photo, name, username and bio. The photo is saved as soon as it is
/// picked; the text fields when Save is pressed.
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
  FeedAuthor? _user;
  bool _loaded = false, _saving = false, _photoBusy = false;
  String? _usernameError, _saveError, _photoError;

  static final _usernamePattern = RegExp(r'^[a-z0-9._]{3,30}$');

  @override
  void initState() {
    super.initState();
    _repo.currentProfile().then((p) {
      if (!mounted) return;
      setState(() {
        _user = p.user;
        _name.text = p.user.displayName ?? '';
        _username.text = p.user.username;
        _bio.text = p.bio ?? '';
        _loaded = true;
      });
    }, onError: (_) {
      if (mounted) setState(() => _saveError = context.l10n.loadProfileFailed);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  /// Picks a photo ([pick] true) or removes the current one, then shows the result.
  Future<void> _setPhoto({required bool pick}) async {
    if (_photoBusy) return;
    XFile? photo;
    if (pick) {
      try {
        // Small and square-ish is plenty for a round avatar.
        photo = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      } catch (_) {
        if (mounted) setState(() => _photoError = context.l10n.photosOpenFailed);
        return;
      }
      if (photo == null || !mounted) return;
    }
    setState(() {
      _photoBusy = true;
      _photoError = null;
    });
    try {
      await _repo.setAvatar(photo);
      final p = await _repo.currentProfile();
      if (mounted) setState(() => _user = p.user);
    } catch (_) {
      if (mounted) setState(() => _photoError = context.l10n.profilePhotoFailed);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final username = _username.text.trim().toLowerCase();
    final error = _usernamePattern.hasMatch(username) ? null : context.l10n.usernameRule;
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
        SnackBar(content: Text(AppConfig.demoMode ? context.l10n.savedDemo : context.l10n.profileUpdated)),
      );
      context.pop();
    } catch (_) {
      if (mounted) setState(() => _saveError = context.l10n.saveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), centerTitle: true, title: Text(context.l10n.editProfile, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
      body: !_loaded
          ? (_saveError != null ? Center(child: Text(_saveError!)) : const LoadingState())
          : Column(children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(Tokens.gutter),
                  children: [
                    _PhotoEditor(
                      user: _user!,
                      busy: _photoBusy,
                      error: _photoError,
                      onPick: () => _setPhoto(pick: true),
                      onRemove: () => _setPhoto(pick: false),
                    ),
                    const SizedBox(height: 16),
                    FieldLabel(context.l10n.name),
                    TextField(controller: _name, maxLength: 50, textCapitalization: TextCapitalization.words),
                    const SizedBox(height: 6),
                    FieldLabel(context.l10n.username),
                    TextField(
                      controller: _username,
                      maxLength: 30,
                      autocorrect: false,
                      decoration: InputDecoration(prefixText: '@', errorText: _usernameError),
                    ),
                    const SizedBox(height: 6),
                    FieldLabel(context.l10n.bio, trailing: context.l10n.optional),
                    TextField(controller: _bio, maxLength: 150, minLines: 2, maxLines: 4, textCapitalization: TextCapitalization.sentences),
                  ],
                ),
              ),
              BottomActionBar(
                above: _saveError == null ? null : Padding(padding: const EdgeInsets.only(bottom: 8), child: FieldError(_saveError)),
                child: FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? context.l10n.saving : context.l10n.save)),
              ),
            ]),
    );
  }
}

/// The round photo with buttons to add, change or remove it.
class _PhotoEditor extends StatelessWidget {
  final FeedAuthor user;
  final bool busy;
  final String? error;
  final VoidCallback onPick, onRemove;
  const _PhotoEditor({required this.user, required this.busy, required this.error, required this.onPick, required this.onRemove});

  static const _size = 96.0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hasPhoto = user.avatarUrl != null;
    return Column(children: [
      Semantics(
        button: true,
        label: hasPhoto ? l.changePhoto : l.addPhoto,
        child: GestureDetector(
          onTap: busy ? null : onPick,
          child: Stack(alignment: Alignment.center, children: [
            AuthorAvatar(author: user, size: _size),
            if (busy)
              Container(
                width: _size,
                height: _size,
                decoration: const BoxDecoration(color: Color(0x66000000), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              ),
          ]),
        ),
      ),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        TextButton(onPressed: busy ? null : onPick, child: Text(hasPhoto ? l.changePhoto : l.addPhoto)),
        if (hasPhoto) TextButton(onPressed: busy ? null : onRemove, child: Text(l.removePhoto)),
      ]),
      if (error != null) FieldError(error),
    ]);
  }
}
