import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SecureStorage {
  // JWT token managment

  static final _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_key';
  static const _fcmTokenKey = 'fcm_token_key';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> saveFcmToken(String token) async {
    await _storage.write(key: _fcmTokenKey, value: token);
  }

  static Future<String?> getFcmToken() async {
    return await _storage.read(key: _fcmTokenKey);
  }

  static Future<void> deleteFcmToken() async {
    await _storage.delete(key: _fcmTokenKey);
  }

  static String getRoleFromToken(String token) {
    Map<String, dynamic> decoded = JwtDecoder.decode(token);
    return decoded['role'];
  }

  static String getEmailFromToken(String token) {
    Map<String, dynamic> decoded = JwtDecoder.decode(token);
    return decoded['sub']?.toString() ?? '';
  }
}
