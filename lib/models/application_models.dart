import 'core/app_enums.dart';
import 'core/json_utils.dart';

class ApplicationResponseDto {
  final int? id;
  final StateApplication? state;
  final String reviewMessage;
  final int userId;
  final List<String> documentationsNames;

  const ApplicationResponseDto({
    this.id,
    this.state,
    required this.reviewMessage,
    required this.userId,
    required this.documentationsNames,
  });

  factory ApplicationResponseDto.fromJson(Map<String, dynamic> json) {
    return ApplicationResponseDto(
      id: JsonUtils.asInt(json['id']),
      state: EnumMapper.stateApplicationFromJson(json['state']?.toString()),
      reviewMessage: json['reviewMessage']?.toString() ?? '',
      userId: JsonUtils.asInt(json['userId']) ?? 0,
      documentationsNames: JsonUtils.asStringList(json['documentationsNames']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'state': EnumMapper.stateApplicationToJson(state),
        'reviewMessage': reviewMessage,
        'userId': userId,
        'documentationsNames': documentationsNames,
      };
}

class ApplicationReviewDto {
  final String reviewMessage;

  const ApplicationReviewDto({
    required this.reviewMessage,
  });

  Map<String, dynamic> toJson() => {
        'reviewMessage': reviewMessage,
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
