import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/theme_controller.dart';

/// System / Light / Dark choice, saved across launches. "System" follows the
/// device's appearance setting.
class AppearancePicker extends StatelessWidget {
  const AppearancePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    final options = [
      (ThemeMode.system, l.appearanceSystem, l.appearanceSystemDescription, Icons.brightness_auto_outlined),
      (ThemeMode.light, l.appearanceLight, l.appearanceLightDescription, Icons.light_mode_outlined),
      (ThemeMode.dark, l.appearanceDark, l.appearanceDarkDescription, Icons.dark_mode_outlined),
    ];
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) => Column(children: [
        for (final (value, label, description, icon) in options)
          Semantics(
            inMutuallyExclusiveGroup: true,
            checked: value == mode,
            button: true,
            label: '$label. $description',
            child: ExcludeSemantics(
              child: ListTile(
                leading: Icon(icon),
                title: Text(label),
                subtitle: Text(description, style: TextStyle(color: scheme.onSurfaceVariant)),
                trailing: Icon(value == mode ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: value == mode ? scheme.onSurface : scheme.outline),
                onTap: () => ThemeController.instance.setMode(value),
              ),
            ),
          ),
      ]),
    );
  }
}
