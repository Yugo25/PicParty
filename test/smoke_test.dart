import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picparty/services/localization_service.dart';
void main(){test('language fallback',(){expect(LocalizationService.detect(const Locale('de')),const Locale('en'));});}
