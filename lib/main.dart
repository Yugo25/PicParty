import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/supabase_config.dart';
import 'services/push_service.dart';
import 'services/preferences_service.dart';
import 'theme/app_theme.dart';
import 'routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  await PreferencesService.instance.init();
  await PushService.instance.init();
  runApp(const PicPartyApp());
}

class PicPartyApp extends StatefulWidget {
  const PicPartyApp({super.key});
  @override State<PicPartyApp> createState() => _PicPartyAppState();
}

class _PicPartyAppState extends State<PicPartyApp> {
  ThemeMode _mode = ThemeMode.system;
  Color _seed = const Color(0xFF6750A4);
  @override Widget build(BuildContext context) => MaterialApp.router(
    title: '图趴 PicParty', debugShowCheckedModeBanner: false,
    theme: AppTheme.light(_seed), darkTheme: AppTheme.dark(_seed), themeMode: _mode,
    localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    supportedLocales: const [Locale('en'), Locale('fr'), Locale('ja'), Locale('ko'), Locale('es'), Locale.fromSubtags(languageCode:'zh',scriptCode:'Hans'), Locale.fromSubtags(languageCode:'zh',scriptCode:'Hant')],
    routerConfig: AppRouter.router,
  );
}
