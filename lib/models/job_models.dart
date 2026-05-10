import 'core/json_utils.dart';

class JobResponseDto {
  final int? id;
  final String name;
  final String description;
  final double? price;
  final int durationMinutes;
  final String categoryName;

  const JobResponseDto({
    this.id,
    required this.name,
    required this.description,
    this.price,
    required this.durationMinutes,
    required this.categoryName,
  });

  factory JobResponseDto.fromJson(Map<String, dynamic> json) {
    return JobResponseDto(
      id: JsonUtils.asInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: JsonUtils.asDouble(json['price']),
      durationMinutes: JsonUtils.asInt(json['durationMinutes']) ?? 0,
      categoryName: json['categoryName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'durationMinutes': durationMinutes,
        'categoryName': categoryName,
      };
}

class JobSaveDto {
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final String categoryName;

  const JobSaveDto({
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.categoryName,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'price': price,
        'durationMinutes': durationMinutes,
        'categoryName': categoryName,
      };
}
