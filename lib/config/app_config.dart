import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const String baseUrlLocal = String.fromEnvironment(
    'API_BASE_URL_LOCAL',
    defaultValue: 'http://localhost:8081',
  );

  static const String baseUrlHost = String.fromEnvironment(
    'API_BASE_URL_HOST',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (baseUrlHost.trim().isNotEmpty) {
      return baseUrlHost.trim();
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // En Android emulator "localhost" apunta al emulador, no al backend del host.
      return baseUrlLocal.replaceFirst('localhost', '10.0.2.2');
    }

    return baseUrlLocal;
  }
}