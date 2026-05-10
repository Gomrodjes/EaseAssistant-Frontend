import 'package:ease_assistant_frontend/core/secure_storage.dart';
import 'package:ease_assistant_frontend/models/models.dart';
import 'package:ease_assistant_frontend/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/app_colors.dart';
import '../../config/measures.dart';
import '../admin/admin_home_screen.dart';
import '../user/assistant/assistant_home_screen.dart';
import '../user/client/client_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isSubmitting = false;

  Future<void> _handleRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authService.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (_isSubmitting) return;

    final currentState = _formKey.currentState;
    if (currentState == null || !currentState.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _authService.login(
        LoginRequestDto(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );

      final token = response.data;
      if (token == null || token.isEmpty) {
        throw const AuthException('El backend no devolvio un token valido.');
      }

      await SecureStorage.saveToken(token);
      final role = SecureStorage.getRoleFromToken(token);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inicio de sesion correcto. Rol detectado: $role'),
        ),
      );

      final destination = _screenForRole(role);
      if (destination == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rol no reconocido: $role'),
          ),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => destination),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ha ocurrido un error inesperado al iniciar sesion.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget? _screenForRole(String role) {
    switch (role.trim().toUpperCase()) {
      case 'ROLE_CLIENT':
      case 'CLIENT':
        return const ClientHomeScreen();
      case 'ROLE_ASSISTANT':
      case 'ASSISTANT':
        return const AssistantHomeScreen();
      case 'ROLE_ADMIN':
      case 'ADMIN':
        return const AdminHomeScreen();
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.turquoise,
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(horizontal: 28 * scale),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    Measures.height(context) - MediaQuery.of(context).padding.top,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: 34 * scale),
                    Text(
                      'Iniciar Sesion',
                      style: TextStyle(
                        color: AppColors.turquoise,
                        fontSize: 31 * scale,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 36 * scale),
                    SvgPicture.asset(
                      'assets/images/undraw_login_weas_1.svg',
                      width: 230 * scale,
                      height: 230 * scale,
                    ),
                    SizedBox(height: 38 * scale),
                    _LoginField(
                      hintText: 'Correo electronico',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) {
                          return 'Introduce tu correo.';
                        }
                        if (!email.contains('@')) {
                          return 'Correo no valido.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16 * scale),
                    _LoginField(
                      hintText: 'Contrasena',
                      controller: _passwordController,
                      obscureText: true,
                      validator: (value) {
                        if ((value ?? '').isEmpty) {
                          return 'Introduce tu contrasena.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 28 * scale),
                    SizedBox(
                      width: double.infinity,
                      height: 48 * scale,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.turquoise,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: Colors.black26,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12 * scale),
                          ),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 18 * scale,
                                height: 18 * scale,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Iniciar Sesion',
                                style: TextStyle(
                                  fontSize: 14 * scale,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 46 * scale),
                    Text(
                      'No tienes cuenta?',
                      style: TextStyle(
                        color: AppColors.turquoise,
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Crea una cuenta',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(height: 24 * scale),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.hintText,
    required this.controller,
    required this.validator,
    this.obscureText = false,
    this.keyboardType,
  });

  final String hintText;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: const Color(0xFFC5C5C5),
          fontSize: 12 * scale,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 12 * scale,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20 * scale),
          borderSide: const BorderSide(
            color: AppColors.turquoise,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20 * scale),
          borderSide: const BorderSide(
            color: AppColors.turquoise,
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20 * scale),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20 * scale),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}
