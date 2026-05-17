import 'address_models.dart';
import 'category_models.dart';
import 'job_models.dart';
import 'user_models.dart';

class ServiceBookingSelection {
  final UserResponseDto customer;
  final UserResponseDto assistant;
  final CategoryResponseDto category;
  final JobResponseDto job;
  final AddressResponseDto address;
  final DateTime serviceDate;
  final String startTime;
  final String endTime;
  final String note;

  const ServiceBookingSelection({
    required this.customer,
    required this.assistant,
    required this.category,
    required this.job,
    required this.address,
    required this.serviceDate,
    required this.startTime,
    required this.endTime,
    required this.note,
  });
}
