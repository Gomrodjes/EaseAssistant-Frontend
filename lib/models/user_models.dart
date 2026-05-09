import 'core/app_enums.dart';
import 'core/json_utils.dart';

class UserProfileDto {
  final int? id;
  final String fullName;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String? nationality;
  final String? biography;
  final int numberOfReviews;
  final double averageRating;

  const UserProfileDto({
    this.id,
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.nationality,
    this.biography,
    required this.numberOfReviews,
    required this.averageRating,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      id: JsonUtils.asInt(json['id']),
      fullName: json['fullName']?.toString() ?? '',
      dateOfBirth: JsonUtils.asDate(json['dateOfBirth']),
      gender: EnumMapper.genderFromJson(json['gender']?.toString()),
      nationality: JsonUtils.asString(json['nationality']),
      biography: JsonUtils.asString(json['biography']),
      numberOfReviews: JsonUtils.asInt(json['numberOfReviews']) ?? 0,
      averageRating: JsonUtils.asDouble(json['averageRating']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'dateOfBirth': JsonUtils.formatDate(dateOfBirth),
        'gender': EnumMapper.genderToJson(gender),
        'nationality': nationality,
        'biography': biography,
        'numberOfReviews': numberOfReviews,
        'averageRating': averageRating,
      };
}

class UserResponseDto {
  final int? id;
  final String email;
  final String fullName;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String? nationality;
  final String? biography;
  final String phoneNumber;
  final UserRole? role;
  final bool isActive;
  final bool isVerified;
  final bool documentationVerified;

  const UserResponseDto({
    this.id,
    required this.email,
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.nationality,
    this.biography,
    required this.phoneNumber,
    this.role,
    required this.isActive,
    required this.isVerified,
    required this.documentationVerified,
  });

  factory UserResponseDto.fromJson(Map<String, dynamic> json) {
    return UserResponseDto(
      id: JsonUtils.asInt(json['id']),
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      dateOfBirth: JsonUtils.asDate(json['dateOfBirth']),
      gender: EnumMapper.genderFromJson(json['gender']?.toString()),
      nationality: JsonUtils.asString(json['nationality']),
      biography: JsonUtils.asString(json['biography']),
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      role: EnumMapper.userRoleFromJson(json['role']?.toString()),
      isActive: JsonUtils.asBool(json['active'] ?? json['isActive']) ?? false,
      isVerified: JsonUtils.asBool(json['verified'] ?? json['isVerified']) ?? false,
      documentationVerified:
          JsonUtils.asBool(json['documentationVerified']) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'dateOfBirth': JsonUtils.formatDate(dateOfBirth),
        'gender': EnumMapper.genderToJson(gender),
        'nationality': nationality,
        'biography': biography,
        'phoneNumber': phoneNumber,
        'role': EnumMapper.userRoleToJson(role),
        'isActive': isActive,
        'isVerified': isVerified,
        'documentationVerified': documentationVerified,
      };
}

class UserSaveDto {
  final String email;
  final String password;
  final String fullName;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String? nationality;
  final String? biography;
  final String phoneNumber;

  const UserSaveDto({
    required this.email,
    required this.password,
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.nationality,
    this.biography,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'fullName': fullName,
        'dateOfBirth': JsonUtils.formatDate(dateOfBirth),
        'gender': EnumMapper.genderToJson(gender),
        'nationality': nationality,
        'biography': biography,
        'phoneNumber': phoneNumber,
      };
}

class UserUpdateDto {
  final String email;
  final String fullName;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String? nationality;
  final String? biography;
  final String phoneNumber;

  const UserUpdateDto({
    required this.email,
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.nationality,
    this.biography,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'fullName': fullName,
        'dateOfBirth': JsonUtils.formatDate(dateOfBirth),
        'gender': EnumMapper.genderToJson(gender),
        'nationality': nationality,
        'biography': biography,
        'phoneNumber': phoneNumber,
      };
}
