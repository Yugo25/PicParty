import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/mock/mock_network.dart';
import '../../theme/tokens.dart';
import '../../widgets/appearance_picker.dart';
import '../../widgets/common/app_back_button.dart';

/// Settings, opened from the gear on your profile.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), centerTitle: true, title: const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
      body: ListView(
        padding: EdgeInsets.only(bottom: 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          const _Section('Appearance'),
          const AppearancePicker(),
          const Divider(indent: Tokens.gutter, endIndent: Tokens.gutter),
          const _Section('Language'),
          const ListTile(enabled: false, leading: Icon(Icons.language), title: Text('App language'), trailing: Text('Coming soon')),
          if (AppConfig.demoMode) ...[
            const Divider(indent: Tokens.gutter, endIndent: Tokens.gutter),
            const _Section('Demo'),
            Padding(
              padding: const EdgeInsets.fromLTRB(Tokens.gutter, 0, Tokens.gutter, 8),
              child: Text(
                'This build has no server. Parties, messages and activity are sample data that stay on this device.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: MockNetwork.simulateErrors,
              builder: (context, on, _) => SwitchListTile(
                value: on,
                onChanged: (v) => MockNetwork.simulateErrors.value = v,
                title: const Text('Simulate connection errors'),
                subtitle: Text('Preview how lists and forms behave offline', style: TextStyle(color: scheme.onSurfaceVariant)),
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
