typedef FromJson<T> = T Function(Map<String, dynamic> json);

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;

  const ApiResponse({
    required this.success,
    required this.data,
    required this.message,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic data) parser,
  ) {
    return ApiResponse<T>(
      success: json['success'] == true,
      data: json['data'] == null ? null : parser(json['data']),
      message: json['message']?.toString() ?? '',
    );
  }
}
