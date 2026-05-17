import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../core/secure_storage.dart';
import '../models/models.dart';

class PaymentServiceException implements Exception {
  final String message;

  const PaymentServiceException(this.message);

  @override
  String toString() => message;
}

class PaymentService {
  PaymentService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri _buildUri(String path) => Uri.parse('$_baseUrl$path');

  Future<ApiResponse<PaymentResponseDto>> createPayment(
    PaymentSaveDto request,
  ) async {
    final authToken = await SecureStorage.getToken();
    final response = await _client.post(
      _buildUri('/payments/create'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(request.toJson()),
    );

    return _parseResponse<PaymentResponseDto>(
      response,
      (data) => PaymentResponseDto.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  Future<ApiResponse<PaymentResponseDto>> updatePayment(
    int paymentId,
    PaymentUpdateDto request,
  ) async {
    final authToken = await SecureStorage.getToken();
    final response = await _client.put(
      _buildUri('/payments/updateState/$paymentId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(request.toJson()),
    );

    return _parseResponse<PaymentResponseDto>(
      response,
      (data) => PaymentResponseDto.fromJson(
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

    throw PaymentServiceException(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Request failed with status ${response.statusCode}',
    );
  }

  void dispose() {
    _client.close();
  }
}

