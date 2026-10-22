import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/language_controller.dart';

/// System / English / 简体中文 choice, saved across launches. "System" shows
/// Chinese on a Chinese device and English otherwise.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    final options = [
      // Language names are written in their own language so they can be found
      // whichever language is showing.
      (AppLanguage.system, l.languageSystem, l.languageSystemDescription, Icons.phone_iphone),
      (AppLanguage.en, 'English', l.languageEnglishDescription, Icons.translate),
      (AppLanguage.zh, '简体中文', l.languageChineseDescription, Icons.translate),
    ];
    return ListenableBuilder(
      listenable: LanguageController.instance,
      builder: (context, _) {
        final choice = LanguageController.instance.choice;
        return Column(children: [
          for (final (value, label, description, icon) in options)
            Semantics(
              inMutuallyExclusiveGroup: true,
              checked: value == choice,
              button: true,
              label: '$label. $description',
              child: ExcludeSemantics(
                child: ListTile(
                  leading: Icon(icon),
                  title: Text(label),
                  subtitle: Text(description, style: TextStyle(color: scheme.onSurfaceVariant)),
                  trailing: Icon(value == choice ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: value == choice ? scheme.onSurface : scheme.outline),
                  onTap: () => LanguageController.instance.setLanguage(value),
                ),
              ),
            ),
        ]);
      },
    );
  }
}
