import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../core/secure_storage.dart';
import '../models/models.dart';

class UserServiceException implements Exception {
  final String message;

  const UserServiceException(this.message);

  @override
  String toString() => message;
}

class UserService {
  UserService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri _buildUri(String path) => Uri.parse('$_baseUrl$path');

  Future<ApiResponse<List<UserResponseDto>>> getAllUsers() async {
    final authToken = await SecureStorage.getToken();
    final response = await _client.get(
      _buildUri('/users'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      },
    );

    return _parseResponse<List<UserResponseDto>>(
      response,
      (data) => (data as List<dynamic>)
          .map(
            (item) =>
                UserResponseDto.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  Future<UserResponseDto> getUserById(int userId) async {
    final response = await getAllUsers();
    final users = response.data ?? const <UserResponseDto>[];
    UserResponseDto? user;

    for (final item in users) {
      if (item.id == userId) {
        user = item;
        break;
      }
    }

    if (user == null) {
      throw const UserServiceException('No se pudo obtener el usuario.');
    }

    return user;
  }

  Future<ApiResponse<UserResponseDto>> updateUserRole(
    int userId,
    UserRoleUpdateDto request,
  ) async {
    final response = await _client.put(
      _buildUri('/auth/select-account-type/$userId'),
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

  Future<ApiResponse<UserResponseDto>> updateUserActiveStatus(
    int userId,
    bool isActive,
  ) async {
    final authToken = await SecureStorage.getToken();
    final response = await _client.put(
      _buildUri('/users/$userId/active/$isActive'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      },
    );

    return _parseResponse<UserResponseDto>(
      response,
      (data) => UserResponseDto.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<ApiResponse<void>> deleteUser(int userId) async {
    final authToken = await SecureStorage.getToken();
    final response = await _client.delete(
      _buildUri('/users/delete/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      },
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

    throw UserServiceException(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Request failed with status ${response.statusCode}',
    );
  }

  void dispose() {
    _client.close();
  }
}
