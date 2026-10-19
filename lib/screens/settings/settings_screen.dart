import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../l10n/l10n.dart';
import '../../services/mock/mock_network.dart';
import '../../theme/tokens.dart';
import '../../widgets/appearance_picker.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/language_picker.dart';

/// Settings, opened from the gear on your profile.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), centerTitle: true, title: Text(l.settings, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
      body: ListView(
        padding: EdgeInsets.only(bottom: 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          _Section(l.appearance),
          const AppearancePicker(),
          const Divider(indent: Tokens.gutter, endIndent: Tokens.gutter),
          _Section(l.language),
          const LanguagePicker(),
          if (AppConfig.demoMode) ...[
            const Divider(indent: Tokens.gutter, endIndent: Tokens.gutter),
            _Section(l.demo),
            Padding(
              padding: const EdgeInsets.fromLTRB(Tokens.gutter, 0, Tokens.gutter, 8),
              child: Text(
                l.demoNotice,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: MockNetwork.simulateErrors,
              builder: (context, on, _) => SwitchListTile(
                value: on,
                onChanged: (v) => MockNetwork.simulateErrors.value = v,
                title: Text(l.simulateErrors),
                subtitle: Text(l.simulateErrorsDescription, style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Tokens.gutter, 18, Tokens.gutter, 6),
        child: Semantics(header: true, child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
      );
}
