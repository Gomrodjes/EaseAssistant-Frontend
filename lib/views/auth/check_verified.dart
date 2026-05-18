import 'dart:async';

import 'package:ease_assistant_frontend/models/models.dart';
import 'package:ease_assistant_frontend/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_colors.dart';
import '../../config/measures.dart';
import 'login_screen.dart';

class CheckVerifiedScreen extends StatefulWidget {
  const CheckVerifiedScreen({
    super.key,
    required this.user,
  });

  final UserResponseDto user;

  @override
  State<CheckVerifiedScreen> createState() => _CheckVerifiedScreenState();
}

class _CheckVerifiedScreenState extends State<CheckVerifiedScreen> {
  final _authService = AuthService();

  Timer? _pollingTimer;
  late UserResponseDto _currentUser;
  bool _isChecking = false;
  bool _isSendingEmail = false;
  bool _isContinuing = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _sendVerificationEmail();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _authService.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _refreshVerificationStatus(showErrors: false);
    });
  }

  Future<void> _sendVerificationEmail() async {
    if (_currentUser.isVerified || _isSendingEmail) return;

    setState(() {
      _isSendingEmail = true;
    });

    try {
      await _authService.sendVerificationEmail(
        VerificationEmailRequestDto(email: _currentUser.email),
      );
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('No se pudo enviar el correo de verificacion.');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingEmail = false;
        });
      }
    }
  }

  Future<void> _refreshVerificationStatus({bool showErrors = true}) async {
    final userId = _currentUser.id;
    if (userId == null || _isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      final response = await _authService.getVerificationStatus(userId);
      final updatedUser = response.data;
      if (updatedUser == null) {
        throw const AuthException('No se pudo obtener el estado de verificacion.');
      }

      if (!mounted) return;

      final wasVerified = _currentUser.isVerified;
      setState(() {
        _currentUser = updatedUser;
      });

      if (!wasVerified && updatedUser.isVerified) {
        _pollingTimer?.cancel();
        _showMessage('Correo verificado correctamente. Ya puedes continuar.');
      }
    } on AuthException catch (e) {
      if (showErrors) {
        _showMessage(e.message);
      }
    } catch (_) {
      if (showErrors) {
        _showMessage('No se pudo comprobar la verificacion del correo.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _continueToLogin() async {
    if (_isContinuing || !_currentUser.isVerified) return;

    setState(() {
      _isContinuing = true;
    });

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);
    final isVerified = _currentUser.isVerified;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 18 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20 * scale),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 28 * scale,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Verificacion\n',
                      style: TextStyle(color: AppColors.purple),
                    ),
                    TextSpan(
                      text: 'de Email',
                      style: TextStyle(color: AppColors.turquoise),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24 * scale),
              Expanded(
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/undraw_emails_1.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: 12 * scale),
              Text(
                isVerified
                    ? 'Tu correo ya esta verificado.'
                    : 'Te hemos enviado un correo a ${_currentUser.email}. Verificalo para continuar.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.navyBlue,
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 14 * scale),
              TextButton(
                onPressed: _isSendingEmail ? null : _sendVerificationEmail,
                child: Text(
                  _isSendingEmail ? 'Enviando correo...' : 'Reenviar correo',
                  style: GoogleFonts.poppins(
                    color: AppColors.purple,
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: _isChecking ? null : () => _refreshVerificationStatus(),
                child: Text(
                  _isChecking ? 'Comprobando...' : 'Comprobar verificacion',
                  style: GoogleFonts.poppins(
                    color: AppColors.turquoise,
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Divider(color: AppColors.turquoise.withValues(alpha: 0.55)),
              SizedBox(height: 20 * scale),
              SizedBox(
                height: 52 * scale,
                child: ElevatedButton(
                  onPressed: isVerified ? _continueToLogin : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.turquoise,
                    disabledBackgroundColor: AppColors.turquoise.withValues(alpha: 0.45),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white70,
                    elevation: 4,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14 * scale),
                    ),
                  ),
                  child: _isContinuing
                      ? SizedBox(
                          width: 18 * scale,
                          height: 18 * scale,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Seguir',
                          style: GoogleFonts.poppins(
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 8 * scale),
            ],
          ),
        ),
      ),
    );
  }
}
