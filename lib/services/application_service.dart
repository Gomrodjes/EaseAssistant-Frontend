import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../core/secure_storage.dart';
import '../models/models.dart';

class ApplicationServiceException implements Exception {
  final String message;

  const ApplicationServiceException(this.message);

  @override
  String toString() => message;
}

class ApplicationService {
  static const Duration _requestTimeout = Duration(seconds: 12);

  ApplicationService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri _buildUri(String path) => Uri.parse('$_baseUrl$path');

  Future<ApiResponse<List<ApplicationResponseDto>>> getAllApplications() async {
    final authToken = await SecureStorage.getToken();
    final response = await _sendRequest(() {
      return _client.get(
        _buildUri('/applications'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (authToken != null && authToken.isNotEmpty)
            'Authorization': 'Bearer $authToken',
        },
      );
    });

    return _parseResponse<List<ApplicationResponseDto>>(
      response,
      (data) => (data as List<dynamic>)
          .map(
            (item) => ApplicationResponseDto.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  Future<ApiResponse<ApplicationResponseDto>> approveApplication(
    int applicationId,
    ApplicationReviewDto request,
  ) async {
    final authToken = await SecureStorage.getToken();
    final response = await _sendRequest(() {
      return _client.put(
        _buildUri('/applications/approved/$applicationId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (authToken != null && authToken.isNotEmpty)
            'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(request.toJson()),
      );
    });

    return _parseResponse<ApplicationResponseDto>(
      response,
      (data) => ApplicationResponseDto.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  Future<ApiResponse<ApplicationResponseDto>> createApplication(
    ApplicationSaveDto request,
  ) async {
    final authToken = await SecureStorage.getToken();
    final response = await _sendRequest(() {
      return _client.post(
        _buildUri('/applications/create'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (authToken != null && authToken.isNotEmpty)
            'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(request.toJson()),
      );
    });

    return _parseResponse<ApplicationResponseDto>(
      response,
      (data) => ApplicationResponseDto.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  Future<ApiResponse<ApplicationResponseDto>> denyApplication(
    int applicationId,
    ApplicationReviewDto request,
  ) async {
    final authToken = await SecureStorage.getToken();
    final response = await _sendRequest(() {
      return _client.put(
        _buildUri('/applications/denied/$applicationId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (authToken != null && authToken.isNotEmpty)
            'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(request.toJson()),
      );
    });

    return _parseResponse<ApplicationResponseDto>(
      response,
      (data) => ApplicationResponseDto.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
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

    throw ApplicationServiceException(
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
      throw const ApplicationServiceException(
        'La conexion con el servidor ha tardado demasiado.',
      );
    } on SocketException {
      throw const ApplicationServiceException(
        'No se pudo conectar con el servidor. Revisa la red y la URL de la API.',
      );
    } on http.ClientException catch (error) {
      throw ApplicationServiceException('Error de red: ${error.message}');
    }
  }

  Map<String, dynamic> _decodeResponseBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      throw const ApplicationServiceException(
        'El servidor devolvio una respuesta no valida.',
      );
    }

    throw const ApplicationServiceException(
      'El servidor devolvio una respuesta no valida.',
    );
  }

  void dispose() {
    _client.close();
  }
}
