import 'core/app_enums.dart';
import 'core/json_utils.dart';

class PaymentResponseDto {
  final int? id;
  final double? amount;
  final double? commissionPercentage;
  final double? platformCommission;
  final double? workerAmount;
  final StatePayment? state;
  final String? stripePaymentId;
  final int bookingId;

  const PaymentResponseDto({
    this.id,
    this.amount,
    this.commissionPercentage,
    this.platformCommission,
    this.workerAmount,
    this.state,
    this.stripePaymentId,
    required this.bookingId,
  });

  factory PaymentResponseDto.fromJson(Map<String, dynamic> json) {
    return PaymentResponseDto(
      id: JsonUtils.asInt(json['id']),
      amount: JsonUtils.asDouble(json['amount']),
      commissionPercentage: JsonUtils.asDouble(json['commissionPercentage']),
      platformCommission: JsonUtils.asDouble(json['platformCommission']),
      workerAmount: JsonUtils.asDouble(json['workerAmount']),
      state: EnumMapper.statePaymentFromJson(json['state']?.toString()),
      stripePaymentId: JsonUtils.asString(json['stripePaymentId']),
      bookingId: JsonUtils.asInt(json['bookingId']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'commissionPercentage': commissionPercentage,
        'platformCommission': platformCommission,
        'workerAmount': workerAmount,
        'state': EnumMapper.statePaymentToJson(state),
        'stripePaymentId': stripePaymentId,
        'bookingId': bookingId,
      };
}

class PaymentSaveDto {
  final double amount;
  final double commissionPercentage;
  final int bookingId;
  final String? stripePaymentId;

  const PaymentSaveDto({
    required this.amount,
    required this.commissionPercentage,
    required this.bookingId,
    this.stripePaymentId,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'commissionPercentage': commissionPercentage,
        'bookingId': bookingId,
        'stripePaymentId': stripePaymentId,
      };
}

class PaymentUpdateDto {
  final StatePayment state;
  final String? stripePaymentId;

  const PaymentUpdateDto({
    required this.state,
    this.stripePaymentId,
  });

  Map<String, dynamic> toJson() => {
        'state': EnumMapper.statePaymentToJson(state),
        'stripePaymentId': stripePaymentId,
      };
}
