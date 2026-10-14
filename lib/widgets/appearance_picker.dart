import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';

/// System / Light / Dark switch, saved across launches.
class AppearancePicker extends StatelessWidget {
  const AppearancePicker({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.instance,
        builder: (context, mode, _) => SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto_outlined)),
            ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
          ],
          selected: {mode},
          onSelectionChanged: (s) => ThemeController.instance.setMode(s.first),
        ),
      );
}
