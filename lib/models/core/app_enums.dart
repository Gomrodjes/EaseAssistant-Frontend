enum Gender { male, female, other }

enum StateApplication { denied, approved, pending }

enum StateBooking { completed, inProgress, canceled, waiting }

enum StatePayment { pending, paid, failed, refunded }

enum TypeDocument {
  dniFront,
  dniBack,
  selfie,
  passport,
  backgroundCheckCertificate,
  socialSecurityDocument,
  trainingCertificate,
  reta,
  other,
}

enum UserRole { client, assistant, admin }

class EnumMapper {
  const EnumMapper._();

  static Gender? genderFromJson(String? value) {
    switch (value) {
      case 'MALE':
        return Gender.male;
      case 'FEMALE':
        return Gender.female;
      case 'OTHER':
        return Gender.other;
      default:
        return null;
    }
  }

  static String? genderToJson(Gender? value) {
    switch (value) {
      case Gender.male:
        return 'MALE';
      case Gender.female:
        return 'FEMALE';
      case Gender.other:
        return 'OTHER';
      case null:
        return null;
    }
  }

  static StateApplication? stateApplicationFromJson(String? value) {
    switch (value) {
      case 'DENIED':
        return StateApplication.denied;
      case 'APPROVED':
        return StateApplication.approved;
      case 'PENDING':
        return StateApplication.pending;
      default:
        return null;
    }
  }

  static String? stateApplicationToJson(StateApplication? value) {
    switch (value) {
      case StateApplication.denied:
        return 'DENIED';
      case StateApplication.approved:
        return 'APPROVED';
      case StateApplication.pending:
        return 'PENDING';
      case null:
        return null;
    }
  }

  static StateBooking? stateBookingFromJson(String? value) {
    switch (value) {
      case 'COMPLETED':
        return StateBooking.completed;
      case 'IN_PROGRESS':
        return StateBooking.inProgress;
      case 'CANCELED':
        return StateBooking.canceled;
      case 'WAITING':
        return StateBooking.waiting;
      default:
        return null;
    }
  }

  static String? stateBookingToJson(StateBooking? value) {
    switch (value) {
      case StateBooking.completed:
        return 'COMPLETED';
      case StateBooking.inProgress:
        return 'IN_PROGRESS';
      case StateBooking.canceled:
        return 'CANCELED';
      case StateBooking.waiting:
        return 'WAITING';
      case null:
        return null;
    }
  }

  static StatePayment? statePaymentFromJson(String? value) {
    switch (value) {
      case 'PENDING':
        return StatePayment.pending;
      case 'PAID':
        return StatePayment.paid;
      case 'FAILED':
        return StatePayment.failed;
      case 'REFUNDED':
        return StatePayment.refunded;
      default:
        return null;
    }
  }

  static String? statePaymentToJson(StatePayment? value) {
    switch (value) {
      case StatePayment.pending:
        return 'PENDING';
      case StatePayment.paid:
        return 'PAID';
      case StatePayment.failed:
        return 'FAILED';
      case StatePayment.refunded:
        return 'REFUNDED';
      case null:
        return null;
    }
  }

  static TypeDocument? typeDocumentFromJson(String? value) {
    switch (value) {
      case 'DNI_FRONT':
        return TypeDocument.dniFront;
      case 'DNI_BACK':
        return TypeDocument.dniBack;
      case 'SELFIE':
        return TypeDocument.selfie;
      case 'PASSPORT':
        return TypeDocument.passport;
      case 'BACKGROUND_CHECK_CERTIFICATE':
      case 'BACKGOUND_CHECK_CERTIFICATE':
        return TypeDocument.backgroundCheckCertificate;
      case 'SOCIAL_SECURITY_DOCUMENT':
        return TypeDocument.socialSecurityDocument;
      case 'TRAINING_CERTIFICATE':
        return TypeDocument.trainingCertificate;
      case 'RETA':
        return TypeDocument.reta;
      case 'OTHER':
        return TypeDocument.other;
      default:
        return null;
    }
  }

  static String? typeDocumentToJson(TypeDocument? value) {
    switch (value) {
      case TypeDocument.dniFront:
        return 'DNI_FRONT';
      case TypeDocument.dniBack:
        return 'DNI_BACK';
      case TypeDocument.selfie:
        return 'SELFIE';
      case TypeDocument.passport:
        return 'PASSPORT';
      case TypeDocument.backgroundCheckCertificate:
        return 'BACKGROUND_CHECK_CERTIFICATE';
      case TypeDocument.socialSecurityDocument:
        return 'SOCIAL_SECURITY_DOCUMENT';
      case TypeDocument.trainingCertificate:
        return 'TRAINING_CERTIFICATE';
      case TypeDocument.reta:
        return 'RETA';
      case TypeDocument.other:
        return 'OTHER';
      case null:
        return null;
    }
  }

  static UserRole? userRoleFromJson(String? value) {
    switch (value) {
      case 'CLIENT':
        return UserRole.client;
      case 'ASSISTANT':
        return UserRole.assistant;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return null;
    }
  }

  static String? userRoleToJson(UserRole? value) {
    switch (value) {
      case UserRole.client:
        return 'CLIENT';
      case UserRole.assistant:
        return 'ASSISTANT';
      case UserRole.admin:
        return 'ADMIN';
      case null:
        return null;
    }
  }
}
