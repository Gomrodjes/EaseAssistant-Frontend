import 'core/json_utils.dart';

class CategoryResponseDto {
  final int? id;
  final String name;
  final String? description;
  final bool active;
  final List<String> serviceNames;

  const CategoryResponseDto({
    this.id,
    required this.name,
    this.description,
    required this.active,
    required this.serviceNames,
  });

  factory CategoryResponseDto.fromJson(Map<String, dynamic> json) {
    return CategoryResponseDto(
      id: JsonUtils.asInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: JsonUtils.asString(json['description']),
      active: JsonUtils.asBool(json['active']) ?? false,
      serviceNames: JsonUtils.asStringList(json['serviceNames']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'active': active,
        'serviceNames': serviceNames,
      };
}

class CategorySaveDto {
  final String name;
  final String? description;
  final bool active;

  const CategorySaveDto({
    required this.name,
    this.description,
    required this.active,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'active': active,
      };
}

class CategoryUpdateDto {
  final String name;
  final String? description;
  final bool active;

  const CategoryUpdateDto({
    required this.name,
    this.description,
    required this.active,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'active': active,
      };
}
