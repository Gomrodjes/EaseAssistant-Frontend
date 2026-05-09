import 'core/json_utils.dart';

class RatingResponseDto {
  final int? id;
  final int score;
  final String? comment;
  final int bookingId;
  final int appraiserId;
  final int valuedId;

  const RatingResponseDto({
    this.id,
    required this.score,
    this.comment,
    required this.bookingId,
    required this.appraiserId,
    required this.valuedId,
  });

  factory RatingResponseDto.fromJson(Map<String, dynamic> json) {
    return RatingResponseDto(
      id: JsonUtils.asInt(json['id']),
      score: JsonUtils.asInt(json['score']) ?? 0,
      comment: JsonUtils.asString(json['comment']),
      bookingId: JsonUtils.asInt(json['bookingId']) ?? 0,
      appraiserId: JsonUtils.asInt(json['appraiserId']) ?? 0,
      valuedId: JsonUtils.asInt(json['valuedId']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'score': score,
        'comment': comment,
        'bookingId': bookingId,
        'appraiserId': appraiserId,
        'valuedId': valuedId,
      };
}

class RatingSaveDto {
  final int score;
  final String? comment;
  final int bookingId;
  final int appraiserId;
  final int valuedId;

  const RatingSaveDto({
    required this.score,
    this.comment,
    required this.bookingId,
    required this.appraiserId,
    required this.valuedId,
  });

  Map<String, dynamic> toJson() => {
        'score': score,
        'comment': comment,
        'bookingId': bookingId,
        'appraiserId': appraiserId,
        'valuedId': valuedId,
      };
}
