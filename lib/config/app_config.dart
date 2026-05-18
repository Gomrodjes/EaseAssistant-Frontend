import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const String baseUrlLocal = String.fromEnvironment(
    'API_BASE_URL_LOCAL',
    defaultValue: 'http://localhost:8082',
  );

  static const String baseUrlHost = String.fromEnvironment(
    'API_BASE_URL_HOST',
    defaultValue: 'http://172.20.10.2:8082',
  );

  static String get apiBaseUrl {
    if (baseUrlHost.trim().isNotEmpty) {
      return baseUrlHost.trim();
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // En Android emulator, localhost apunta al propio emulador.
      // 10.0.2.2 redirige al host donde corre el backend.
      return baseUrlLocal.replaceFirst('localhost', '10.0.2.2');
    }

    return baseUrlLocal;
  }
}
