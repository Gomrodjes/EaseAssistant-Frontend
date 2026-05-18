import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/models.dart';

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri _buildUri(String path) => Uri.parse('$_baseUrl$path');

  Future<ApiResponse<String>> login(LoginRequestDto request) async {
    final response = await _client.post(
      _buildUri('/auth/login'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    return _parseResponse<String>(
      response,
      (data) => data?.toString() ?? '',
    );
  }

  Future<ApiResponse<UserResponseDto>> register(UserSaveDto request) async {
    final response = await _client.post(
      _buildUri('/auth/register'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    return _parseResponse<UserResponseDto>(
      response,
      (data) => UserResponseDto.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<ApiResponse<void>> sendVerificationEmail(
    VerificationEmailRequestDto request,
  ) async {
    final response = await _client.post(
      _buildUri('/auth/send/verification'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    return _parseResponse<void>(response, (_) {});
  }

  Future<ApiResponse<UserResponseDto>> getVerificationStatus(int userId) async {
    final response = await _client.get(
      _buildUri('/auth/verification-status/$userId'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    return _parseResponse<UserResponseDto>(
      response,
      (data) => UserResponseDto.fromJson(Map<String, dynamic>.from(data as Map)),
    );
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

    throw AuthException(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Request failed with status ${response.statusCode}',
    );
  }

  void dispose() {
    _client.close();
  }
}
