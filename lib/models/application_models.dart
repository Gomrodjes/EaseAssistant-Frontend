import 'core/app_enums.dart';
import 'core/json_utils.dart';

class ApplicationResponseDto {
  final int? id;
  final StateApplication? state;
  final int userId;
  final List<String> documentationsNames;

  const ApplicationResponseDto({
    this.id,
    this.state,
    required this.userId,
    required this.documentationsNames,
  });

  factory ApplicationResponseDto.fromJson(Map<String, dynamic> json) {
    return ApplicationResponseDto(
      id: JsonUtils.asInt(json['id']),
      state: EnumMapper.stateApplicationFromJson(json['state']?.toString()),
      userId: JsonUtils.asInt(json['userId']) ?? 0,
      documentationsNames: JsonUtils.asStringList(json['documentationsNames']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'state': EnumMapper.stateApplicationToJson(state),
        'userId': userId,
        'documentationsNames': documentationsNames,
      };
}

class ApplicationSaveDto {
  final int userId;
  final List<int> documentationsIds;

  const ApplicationSaveDto({
    required this.userId,
    required this.documentationsIds,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'documentationsIDs': documentationsIds,
      };
}
