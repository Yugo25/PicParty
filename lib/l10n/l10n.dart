import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/language_controller.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  /// The app's text in the language chosen in Settings.
  AppLocalizations get l10n => Localizations.of<AppLocalizations>(this, AppLocalizations) ?? L10n.current;
}

/// The app's text for code that has no [BuildContext] (models, formatters).
class L10n {
  L10n._();

  static AppLocalizations get current => lookupAppLocalizations(LanguageController.instance.locale);

  static bool _dateDataLoaded = false;

  /// Locale for intl's [DateFormat] (month names, date order), with its data loaded.
  static String get dateLocale {
    if (!_dateDataLoaded) {
      initializeDateFormatting();
      _dateDataLoaded = true;
    }
    return current.localeName;
  }
}
