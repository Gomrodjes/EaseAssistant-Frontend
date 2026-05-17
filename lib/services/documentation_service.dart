import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../core/secure_storage.dart';
import '../models/models.dart';

class DocumentationServiceException implements Exception {
  final String message;

  const DocumentationServiceException(this.message);

  @override
  String toString() => message;
}

class DocumentationService {
  DocumentationService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri _buildUri(String path) => Uri.parse('$_baseUrl$path');

  Uri getDocumentationFileUri(int documentationId) {
    return _buildUri('/documentations/file/$documentationId');
  }

  Future<ApiResponse<DocumentationResponseDto>> createDocumentation({
    required int userId,
    required TypeDocument type,
    required File file,
  }) async {
    final authToken = await SecureStorage.getToken();
    final request = http.MultipartRequest(
      'POST',
      _buildUri('/documentations/create'),
    );

    request.fields['userId'] = '$userId';
    request.fields['type'] = EnumMapper.typeDocumentToJson(type) ?? '';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    if (authToken != null && authToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }
    request.headers['Accept'] = 'application/json';

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _parseResponse<DocumentationResponseDto>(
      response,
      (data) => DocumentationResponseDto.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  Future<ApiResponse<List<DocumentationResponseDto>>> getAllDocumentationByUser(
    int userId,
  ) async {
    final authToken = await SecureStorage.getToken();
    final response = await _client.get(
      _buildUri('/documentations/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      },
    );

    return _parseResponse<List<DocumentationResponseDto>>(
      response,
      (data) => (data as List<dynamic>)
          .map(
            (item) => DocumentationResponseDto.fromJson(
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

    throw DocumentationServiceException(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Request failed with status ${response.statusCode}',
    );
  }

  void dispose() {
    _client.close();
  }
}
