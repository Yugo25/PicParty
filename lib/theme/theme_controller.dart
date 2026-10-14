import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

/// App-wide light / dark / system appearance, persisted between launches.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.system);
  static final instance = ThemeController._();

  void load() {
    value = switch (PreferencesService.instance.theme.mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void setMode(ThemeMode mode) {
    value = mode;
    PreferencesService.instance.theme.setMode(mode.name);
  }
}
