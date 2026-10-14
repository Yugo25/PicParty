import 'package:flutter_test/flutter_test.dart';
import 'package:picparty/services/feed/auto_advance_controller.dart';

void main() {
  late int advances;
  late AutoAdvanceController auto;

  setUp(() {
    advances = 0;
    auto = AutoAdvanceController(onAdvance: () => advances++, photoInterval: const Duration(seconds: 5));
    auto.onPostShown(isVideo: false);
  });
  tearDown(() => auto.dispose());

  testWidgets('off by default, advances photos every interval once enabled and active', (tester) async {
    auto.setActive(true);
    await tester.pump(const Duration(seconds: 6));
    expect(advances, 0);

    auto.setEnabled(true);
    await tester.pump(const Duration(seconds: 5));
    expect(advances, 1);
  });

  testWidgets('does not run while off screen or suspended', (tester) async {
    auto.setEnabled(true);
    await tester.pump(const Duration(seconds: 10));
    expect(advances, 0);
    auto.setActive(true);
    await tester.pump(const Duration(seconds: 3));
    auto.setActive(false); // scrolled away / detail opened
    await tester.pump(const Duration(seconds: 10));
    expect(advances, 0);
  });

  testWidgets('manual swipe turns it off', (tester) async {
    auto
      ..setActive(true)
      ..setEnabled(true)
      ..onUserSwipe();
    expect(auto.enabled, isFalse);
    await tester.pump(const Duration(seconds: 10));
    expect(advances, 0);
  });

  testWidgets('videos ignore the photo timer and advance when finished', (tester) async {
    auto
      ..setActive(true)
      ..setEnabled(true)
      ..onPostShown(isVideo: true);
    await tester.pump(const Duration(seconds: 30));
    expect(advances, 0);
    auto.onVideoCompleted();
    expect(advances, 1);
  });
}
