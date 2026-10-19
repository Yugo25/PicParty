import 'package:flutter/widgets.dart';
import 'preferences_service.dart';

/// The language choices offered in Settings. Stored as its [name].
enum AppLanguage { system, en, zh }

/// App-wide language (English / Simplified Chinese), persisted between
/// launches. "System" shows Chinese on a Chinese device and English otherwise.
class LanguageController extends ChangeNotifier with WidgetsBindingObserver {
  LanguageController._();
  static final instance = LanguageController._();

  static const english = Locale('en');
  static const chinese = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
  static const supportedLocales = [english, chinese];

  AppLanguage _choice = AppLanguage.system;
  AppLanguage get choice => _choice;

  Locale _locale = english;
  Locale get locale => _locale;

  void load() {
    final saved = PreferencesService.instance.theme.language;
    _choice = AppLanguage.values.firstWhere((l) => l.name == saved, orElse: () => AppLanguage.system);
    _locale = _resolve();
    WidgetsBinding.instance.addObserver(this);
  }

  void setLanguage(AppLanguage choice) {
    _choice = choice;
    PreferencesService.instance.theme.setLanguage(choice.name);
    _update();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (_choice == AppLanguage.system) _update();
  }

  Locale _resolve() => switch (_choice) {
        AppLanguage.en => english,
        AppLanguage.zh => chinese,
        AppLanguage.system => WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'zh' ? chinese : english,
      };

  void _update() {
    final changed = _resolve() != _locale;
    _locale = _resolve();
    notifyListeners();
    if (changed) _rebuildAll();
  }

  /// Some text (timers, dates, labels on models) is looked up without a
  /// BuildContext, so rebuild every widget once to redraw it in the new language.
  static void _rebuildAll() {
    void rebuild(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuild);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
  }
}
