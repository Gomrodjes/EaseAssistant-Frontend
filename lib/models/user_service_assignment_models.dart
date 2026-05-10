import 'core/json_utils.dart';

class UserServiceAssignmentResponseDto {
  final int? id;
  final int userId;
  final String userFullName;
  final int serviceId;
  final String serviceName;
  final bool active;

  const UserServiceAssignmentResponseDto({
    this.id,
    required this.userId,
    required this.userFullName,
    required this.serviceId,
    required this.serviceName,
    required this.active,
  });

  factory UserServiceAssignmentResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return UserServiceAssignmentResponseDto(
      id: JsonUtils.asInt(json['id']),
      userId: JsonUtils.asInt(json['userId']) ?? 0,
      userFullName: json['userFullName']?.toString() ?? '',
      serviceId: JsonUtils.asInt(json['serviceId']) ?? 0,
      serviceName: json['serviceName']?.toString() ?? '',
      active: JsonUtils.asBool(json['active']) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userFullName': userFullName,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'active': active,
      };
}
