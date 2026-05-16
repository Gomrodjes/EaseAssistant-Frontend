import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../core/secure_storage.dart';
import '../models/api/api_response.dart';
import '../models/user_service_assignment_models.dart';

class UserServiceAssignmentServiceException implements Exception {
  final String message;

  const UserServiceAssignmentServiceException(this.message);

  @override
  String toString() => message;
}

class UserServiceAssignmentService {
  UserServiceAssignmentService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri _buildUri(String path) => Uri.parse('$_baseUrl$path');

  Future<ApiResponse<List<UserServiceAssignmentResponseDto>>>
      getAssignmentsByUser(int userId) async {
    final authToken = await SecureStorage.getToken();
    final response = await _client.get(
      _buildUri('/assignments/user/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      },
    );

    return _parseResponse<List<UserServiceAssignmentResponseDto>>(
      response,
      (data) => (data as List<dynamic>)
          .map(
            (item) => UserServiceAssignmentResponseDto.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  Future<ApiResponse<List<UserServiceAssignmentResponseDto>>>
      getAssignmentsByService(int serviceId) async {
    final authToken = await SecureStorage.getToken();
    final response = await _client.get(
      _buildUri('/assignments/service/$serviceId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      },
    );

    return _parseResponse<List<UserServiceAssignmentResponseDto>>(
      response,
      (data) => (data as List<dynamic>)
          .map(
            (item) => UserServiceAssignmentResponseDto.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
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

    throw UserServiceAssignmentServiceException(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Request failed with status ${response.statusCode}',
    );
  }

  void dispose() {
    _client.close();
  }
}
