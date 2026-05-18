import 'package:ease_assistant_frontend/models/models.dart';
import 'package:ease_assistant_frontend/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_colors.dart';
import '../../config/measures.dart';
import 'check_verified.dart';
import 'login_screen.dart';

class TypeAccountScreen extends StatefulWidget {
  const TypeAccountScreen({
    super.key,
    required this.createdUser,
  });

  final UserResponseDto createdUser;

  @override
  State<TypeAccountScreen> createState() => _TypeAccountScreenState();
}

class _TypeAccountScreenState extends State<TypeAccountScreen> {
  final _userService = UserService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _userService.dispose();
    super.dispose();
  }

  Future<void> _goToLogin({String? message}) async {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );

    if (message != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _goToVerification(UserResponseDto user) async {
    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => CheckVerifiedScreen(user: user),
      ),
    );
  }

  Future<void> _becomeAssistant() async {
    if (_isSubmitting) return;

    final userId = widget.createdUser.id;
    if (userId == null) {
      _showMessage('No se pudo identificar el usuario creado.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _userService.updateUserRole(
        userId,
        const UserRoleUpdateDto(role: UserRole.assistant),
      );

      final updatedUser = response.data;
      if (updatedUser == null) {
        throw const UserServiceException('No se pudo actualizar el tipo de cuenta.');
      }

      await _goToVerification(updatedUser);
    } on UserServiceException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Ha ocurrido un error al cambiar el tipo de cuenta.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18 * scale, vertical: 10 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _isSubmitting ? null : () => _goToLogin(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.turquoise,
                  ),
                ),
              ),
              SizedBox(height: 12 * scale),
              Text(
                'Tipo de Cuenta',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.turquoise,
                  fontSize: 28 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 28 * scale),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/images/undraw_choose_5kz4 _1.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: 20 * scale),
                    _AccountTypeButton(
                      label: 'Contratar Ayuda',
                      onPressed: _isSubmitting ? null : () => _goToVerification(widget.createdUser),
                    ),
                    SizedBox(height: 16 * scale),
                    _AccountTypeButton(
                      label: 'Trabajar como ayudante',
                      isLoading: _isSubmitting,
                      onPressed: _becomeAssistant,
                    ),
                    SizedBox(height: 28 * scale),
                    Divider(color: AppColors.turquoise.withValues(alpha: 0.6)),
                    SizedBox(height: 16 * scale),
                    Text(
                      'Gracias por confiar en\nEaseAssistant',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.turquoise,
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTypeButton extends StatelessWidget {
  const _AccountTypeButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return SizedBox(
      width: double.infinity,
      height: 52 * scale,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.turquoise,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13 * scale),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 18 * scale,
                height: 18 * scale,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}
