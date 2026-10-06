import 'package:flutter/material.dart';
class LocalizationService {
  static const supported=[Locale('en'),Locale('fr'),Locale('ja'),Locale('ko'),Locale('es'),Locale.fromSubtags(languageCode:'zh',scriptCode:'Hans'),Locale.fromSubtags(languageCode:'zh',scriptCode:'Hant')];
  static Locale detect(Locale system){ if(system.languageCode=='zh') return Locale.fromSubtags(languageCode:'zh',scriptCode:system.scriptCode=='Hant'?'Hant':'Hans'); return supported.any((l)=>l.languageCode==system.languageCode)?system:const Locale('en'); }
}
