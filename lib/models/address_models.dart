import 'core/json_utils.dart';

class AddressResponseDto {
  final int? id;
  final String street;
  final String city;
  final String country;
  final String zipCode;
  final String? description;
  final bool isPrimary;
  final int userId;

  const AddressResponseDto({
    this.id,
    required this.street,
    required this.city,
    required this.country,
    required this.zipCode,
    this.description,
    required this.isPrimary,
    required this.userId,
  });

  factory AddressResponseDto.fromJson(Map<String, dynamic> json) {
    return AddressResponseDto(
      id: JsonUtils.asInt(json['id']),
      street: json['street']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      zipCode: json['zipCode']?.toString() ?? '',
      description: JsonUtils.asString(json['description']),
      isPrimary: JsonUtils.asBool(json['primary'] ?? json['isPrimary']) ?? false,
      userId: JsonUtils.asInt(json['userId']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'street': street,
        'city': city,
        'country': country,
        'zipCode': zipCode,
        'description': description,
        'isPrimary': isPrimary,
        'userId': userId,
      };
}

class AddressSaveDto {
  final String street;
  final String city;
  final String country;
  final String zipCode;
  final String? description;
  final bool isPrimary;
  final int userId;

  const AddressSaveDto({
    required this.street,
    required this.city,
    required this.country,
    required this.zipCode,
    this.description,
    required this.isPrimary,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
        'street': street,
        'city': city,
        'country': country,
        'zipCode': zipCode,
        'description': description,
        'isPrimary': isPrimary,
        'userId': userId,
      };
}
