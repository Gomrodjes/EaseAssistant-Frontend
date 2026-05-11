import 'dart:convert';

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
    final response = await _client.get(
      _buildUri('/applications'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      },
    );

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
    final response = await _client.put(
      _buildUri('/applications/approved/$applicationId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(request.toJson()),
    );

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
    final response = await _client.put(
      _buildUri('/applications/denied/$applicationId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(request.toJson()),
    );

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
    final decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
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

  void dispose() {
    _client.close();
  }
}
