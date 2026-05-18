import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  static const Duration _requestTimeout = Duration(seconds: 12);

  AuthService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri _buildUri(String path) => Uri.parse('$_baseUrl$path');

  Future<ApiResponse<String>> login(LoginRequestDto request) async {
    final response = await _sendRequest(() {
      return _client.post(
        _buildUri('/auth/login'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );
    });

    return _parseResponse<String>(
      response,
      (data) => data?.toString() ?? '',
    );
  }

  Future<ApiResponse<UserResponseDto>> register(UserSaveDto request) async {
    final response = await _sendRequest(() {
      return _client.post(
        _buildUri('/auth/register'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );
    });

    return _parseResponse<UserResponseDto>(
      response,
      (data) => UserResponseDto.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<ApiResponse<void>> sendVerificationEmail(
    VerificationEmailRequestDto request,
  ) async {
    final response = await _sendRequest(() {
      return _client.post(
        _buildUri('/auth/send/verification'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );
    });

    return _parseResponse<void>(response, (_) {});
  }

  Future<ApiResponse<UserResponseDto>> getVerificationStatus(int userId) async {
    final response = await _sendRequest(() {
      return _client.get(
        _buildUri('/auth/verification-status/$userId'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
    });

    return _parseResponse<UserResponseDto>(
      response,
      (data) => UserResponseDto.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  ApiResponse<T> _parseResponse<T>(
    http.Response response,
    T Function(dynamic data) parser,
  ) {
    final decodedBody = _decodeResponseBody(response.body);
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

  Future<http.Response> _sendRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_requestTimeout);
    } on TimeoutException {
      throw const AuthException(
        'La conexion con el servidor ha tardado demasiado.',
      );
    } on SocketException {
      throw const AuthException(
        'No se pudo conectar con el servidor. Revisa la red y la URL de la API.',
      );
    } on http.ClientException catch (error) {
      throw AuthException('Error de red: ${error.message}');
    }
  }

  Map<String, dynamic> _decodeResponseBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      throw const AuthException('El servidor devolvio una respuesta no valida.');
    }

    throw const AuthException('El servidor devolvio una respuesta no valida.');
  }

  void dispose() {
    _client.close();
  }
}
