import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/app_colors.dart';
import '../../../../config/measures.dart';
import '../../../../core/secure_storage.dart';
import '../../../auth/login_screen.dart';

class WaitingApplicationRespondeScreen extends StatelessWidget {
  const WaitingApplicationRespondeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 24 * scale,
            vertical: 34 * scale,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  Measures.height(context) - MediaQuery.of(context).padding.top,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 18 * scale),
                Padding(
                  padding: EdgeInsets.only(left: 2 * scale),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 34 * scale,
                        fontWeight: FontWeight.w800,
                        height: 1.18,
                        letterSpacing: -0.4,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Cuenta en\n',
                          style: TextStyle(color: AppColors.purple),
                        ),
                        TextSpan(
                          text: 'Revision',
                          style: TextStyle(color: AppColors.turquoise),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 36 * scale),
                SizedBox(
                  width: 318 * scale,
                  child: Text(
                    'Hemos recibido tu informacion.\n'
                    'Tu cuenta sera verificada en un plazo de 24-48h.\n'
                    'Te avisaremos por correo o notificacion\n'
                    'cuando puedas empezar\n'
                    'a trabajar.',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5 * scale,
                      fontWeight: FontWeight.w600,
                      height: 1.65,
                      letterSpacing: 0.1,
                      color: AppColors.turquoise,
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),
                Container(
                  width: 176 * scale,
                  height: 2,
                  color: AppColors.turquoise.withOpacity(0.45),
                ),
                SizedBox(height: 42 * scale),
                Center(
                  child: SizedBox(
                    width: 330 * scale,
                    height: 290 * scale,
                    child: SvgPicture.asset(
                      'assets/images/undraw_loading_3kqt_1.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 24 * scale),
                SizedBox(
                  width: double.infinity,
                  height: 54 * scale,
                  child: ElevatedButton(
                    onPressed: () async {
                      await SecureStorage.deleteToken();
                      if (!context.mounted) return;

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen(),
                        ),
                        (_) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.turquoise,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18 * scale),
                      ),
                    ),
                    child: Text(
                      'Salir',
                      style: GoogleFonts.poppins(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
