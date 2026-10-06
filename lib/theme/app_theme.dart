import 'package:flutter/material.dart';
class AppTheme {
  static ThemeData light(Color seed)=>ThemeData(useMaterial3:true,colorSchemeSeed:seed,brightness:Brightness.light,scaffoldBackgroundColor:const Color(0xFFF8F7FA));
  static ThemeData dark(Color seed)=>ThemeData(useMaterial3:true,colorSchemeSeed:seed,brightness:Brightness.dark);
}
