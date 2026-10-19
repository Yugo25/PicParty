import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/supabase_config.dart';
import 'core/app_clock.dart';
import 'l10n/l10n.dart';
import 'services/language_controller.dart';
import 'services/push_service.dart';
import 'services/preferences_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'routing/app_router.dart';
import 'widgets/common/mobile_frame.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  await PreferencesService.instance.init();
  await PushService.instance.init();
  ThemeController.instance.load();
  LanguageController.instance.load();
  AppClock.instance.start();
  runApp(const PicPartyApp());
}

class PicPartyApp extends StatelessWidget {
  const PicPartyApp({super.key});
  @override Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([ThemeController.instance, LanguageController.instance]),
    builder: (context, _) => MaterialApp.router(
      title: '图趴 PicParty', debugShowCheckedModeBanner: false,
      theme: AppTheme.light(), darkTheme: AppTheme.dark(), themeMode: ThemeController.instance.value,
      locale: LanguageController.instance.locale,
      localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      supportedLocales: LanguageController.supportedLocales,
      routerConfig: AppRouter.router,
      builder: (context, child) => MobileFrame(child: child!),
    ),
  );
}
