import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:picparty/main.dart';
void main(){IntegrationTestWidgetsFlutterBinding.ensureInitialized();testWidgets('PicParty launches', (tester) async {await tester.pumpWidget(const PicPartyApp());await tester.pumpAndSettle();expect(find.text('图趴 PicParty'),findsOneWidget);});}
