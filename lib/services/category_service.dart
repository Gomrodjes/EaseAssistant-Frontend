import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../core/secure_storage.dart';
import '../models/models.dart';

class CategoryServiceException implements Exception {
  final String message;

  const CategoryServiceException(this.message);

  @override
  String toString() => message;
}

class CategoryService {
  CategoryService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri _buildUri(String path) => Uri.parse('$_baseUrl$path');

  Future<ApiResponse<List<CategoryResponseDto>>> getAllCategories() async {
    final authToken = await SecureStorage.getToken();
    final response = await _client.get(
      _buildUri('/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      },
    );

    return _parseResponse<List<CategoryResponseDto>>(
      response,
      (data) => (data as List<dynamic>)
          .map(
            (item) => CategoryResponseDto.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  Future<ApiResponse<CategoryResponseDto>> createCategory(
    CategorySaveDto request,
  ) async {
    final authToken = await SecureStorage.getToken();
    final response = await _client.post(
      _buildUri('/categories/create'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(request.toJson()),
    );

    return _parseResponse<CategoryResponseDto>(
      response,
      (data) => CategoryResponseDto.fromJson(
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

    throw CategoryServiceException(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Request failed with status ${response.statusCode}',
    );
  }

  void dispose() {
    _client.close();
  }
}
