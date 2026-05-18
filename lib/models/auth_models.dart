class LoginRequestDto {
  final String email;
  final String password;

  const LoginRequestDto({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class VerificationEmailRequestDto {
  final String email;

  const VerificationEmailRequestDto({
    required this.email,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
      };
}
