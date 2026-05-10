import 'core/app_enums.dart';
import 'core/json_utils.dart';

class DocumentationResponseDto {
  final int? id;
  final String originalFileName;
  final String storedFileName;
  final String filePath;
  final TypeDocument? type;
  final DateTime? uploadDate;
  final int userId;
  final int? applicationId;

  const DocumentationResponseDto({
    this.id,
    required this.originalFileName,
    required this.storedFileName,
    required this.filePath,
    this.type,
    this.uploadDate,
    required this.userId,
    this.applicationId,
  });

  factory DocumentationResponseDto.fromJson(Map<String, dynamic> json) {
    return DocumentationResponseDto(
      id: JsonUtils.asInt(json['id']),
      originalFileName: json['originalFileName']?.toString() ?? '',
      storedFileName: json['storedFileName']?.toString() ?? '',
      filePath: json['filePath']?.toString() ?? '',
      type: EnumMapper.typeDocumentFromJson(json['type']?.toString()),
      uploadDate: JsonUtils.asDate(json['uploadDate']),
      userId: JsonUtils.asInt(json['userId']) ?? 0,
      applicationId: JsonUtils.asInt(json['applicationId']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalFileName': originalFileName,
        'storedFileName': storedFileName,
        'filePath': filePath,
        'type': EnumMapper.typeDocumentToJson(type),
        'uploadDate': JsonUtils.formatDate(uploadDate),
        'userId': userId,
        'applicationId': applicationId,
      };
}

class DocumentationSaveDto {
  final TypeDocument type;
  final int userId;

  const DocumentationSaveDto({
    required this.type,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
        'type': EnumMapper.typeDocumentToJson(type),
        'userId': userId,
      };
}
