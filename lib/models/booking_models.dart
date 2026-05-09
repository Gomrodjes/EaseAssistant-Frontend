import 'core/app_enums.dart';
import 'core/json_utils.dart';

class BookingCancellationDto {
  final String? cancellationReason;

  const BookingCancellationDto({this.cancellationReason});

  Map<String, dynamic> toJson() => {
        'cancellationReason': cancellationReason,
      };
}

class BookingResponseDto {
  final int? id;
  final DateTime? dateBooking;
  final String? startTime;
  final String? endTime;
  final double? totalPrice;
  final StateBooking? state;
  final String? clientNote;
  final int addressId;

  const BookingResponseDto({
    this.id,
    this.dateBooking,
    this.startTime,
    this.endTime,
    this.totalPrice,
    this.state,
    this.clientNote,
    required this.addressId,
  });

  factory BookingResponseDto.fromJson(Map<String, dynamic> json) {
    return BookingResponseDto(
      id: JsonUtils.asInt(json['id']),
      dateBooking: JsonUtils.asDate(json['dateBooking']),
      startTime: JsonUtils.asString(json['startTime']),
      endTime: JsonUtils.asString(json['endTime']),
      totalPrice: JsonUtils.asDouble(json['totalPrice']),
      state: EnumMapper.stateBookingFromJson(json['state']?.toString()),
      clientNote: JsonUtils.asString(json['clientNote']),
      addressId: JsonUtils.asInt(json['addressId']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateBooking': JsonUtils.formatDate(dateBooking),
        'startTime': startTime,
        'endTime': endTime,
        'totalPrice': totalPrice,
        'state': EnumMapper.stateBookingToJson(state),
        'clientNote': clientNote,
        'addressId': addressId,
      };
}

class BookingSaveDto {
  final DateTime dateBooking;
  final String startTime;
  final String? clientNote;
  final int customerId;
  final int workerId;
  final int jobId;
  final int addressId;

  const BookingSaveDto({
    required this.dateBooking,
    required this.startTime,
    this.clientNote,
    required this.customerId,
    required this.workerId,
    required this.jobId,
    required this.addressId,
  });

  Map<String, dynamic> toJson() => {
        'dateBooking': JsonUtils.formatDate(dateBooking),
        'startTime': startTime,
        'clientNote': clientNote,
        'customerId': customerId,
        'workerId': workerId,
        'jobId': jobId,
        'addressId': addressId,
      };
}

class BookingUpdateDto {
  final DateTime dateBooking;
  final String startTime;
  final String? clientNote;
  final int addressId;

  const BookingUpdateDto({
    required this.dateBooking,
    required this.startTime,
    this.clientNote,
    required this.addressId,
  });

  Map<String, dynamic> toJson() => {
        'dateBooking': JsonUtils.formatDate(dateBooking),
        'startTime': startTime,
        'clientNote': clientNote,
        'addressId': addressId,
      };
}
