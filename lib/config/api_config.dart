/// Central place to configure how the Flutter app talks to the
/// Django REST backend.
///
/// Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
///
/// Defaults:
///  - Android emulator can't reach `localhost` of the host machine, so we
///    default to the special `10.0.2.2` alias there.
///  - Everything else (iOS simulator, web, desktop) defaults to localhost.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:8000/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    } catch (_) {
      // Platform is unavailable on some targets (e.g. tests) - ignore.
    }
    return 'http://localhost:8000/api';
  }

  static const Duration requestTimeout = Duration(seconds: 20);
}
