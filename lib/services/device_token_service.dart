import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../core/secure_storage.dart';
import '../models/api/api_response.dart';

class DeviceTokenServiceException implements Exception {
  final String message;

  const DeviceTokenServiceException(this.message);

  @override
  String toString() => message;
}

class DeviceTokenService {
  DeviceTokenService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri _buildUri(String path) => Uri.parse('$_baseUrl$path');

  Future<ApiResponse<void>> registerToken({
    required String token,
    required String platform,
    String? deviceName,
  }) async {
    final authToken = await SecureStorage.getToken();
    final response = await _client.post(
      _buildUri('/device-tokens/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'token': token,
        'platform': platform,
        'deviceName': deviceName,
      }),
    );

    return _parseResponse<void>(response, (_) {});
  }

  Future<ApiResponse<void>> unregisterToken(String token) async {
    final authToken = await SecureStorage.getToken();
    final response = await _client.post(
      _buildUri('/device-tokens/unregister'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({'token': token}),
    );

    return _parseResponse<void>(response, (_) {});
  }

  ApiResponse<T> _parseResponse<T>(
    http.Response response,
    T Function(dynamic data) parser,
  ) {
    final decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
    final apiResponse = ApiResponse<T>.fromJson(decodedBody, parser);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return apiResponse;
    }

    throw DeviceTokenServiceException(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Request failed with status ${response.statusCode}',
    );
  }

  void dispose() {
    _client.close();
  }
}
