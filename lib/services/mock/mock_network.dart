import 'package:flutter/foundation.dart';
import '../../core/app_exception.dart';

/// Latency and failure simulation for the mock repositories, so loading and
/// error states can be checked without a backend. Toggled from Settings.
class MockNetwork {
  MockNetwork._();

  /// When true, every mock request fails.
  static final simulateErrors = ValueNotifier<bool>(false);

  /// Waits like a network call would, then fails if errors are simulated.
  static Future<void> request([Duration latency = const Duration(milliseconds: 300)]) async {
    await Future<void>.delayed(latency);
    if (simulateErrors.value) throw const AppException('offline', 'Couldn\'t connect. Check your connection and try again.');
  }
}
