import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/app_colors.dart';
import '../../config/measures.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _handleRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
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
                  const _LoginField(hintText: 'Correo electronico'),
                  SizedBox(height: 16 * scale),
                  const _LoginField(
                    hintText: 'Contrasena',
                    obscureText: true,
                  ),
                  SizedBox(height: 28 * scale),
                  SizedBox(
                    width: double.infinity,
                    height: 48 * scale,
                    child: ElevatedButton(
                      onPressed: () {}, // TODO: enlazar con backend.
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.turquoise,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12 * scale),
                        ),
                      ),
                      child: Text(
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
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.hintText,
    this.obscureText = false,
  });

  final String hintText;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return TextField(
      obscureText: obscureText,
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
      ),
    );
  }
}
