import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/app_colors.dart';
import '../../../config/measures.dart';
import 'application/assistant_identity_verification_screen.dart';

class AssistantVerifyHomeScreen extends StatelessWidget {
  const AssistantVerifyHomeScreen({super.key});

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
                          text: 'Hazte\n',
                          style: TextStyle(color: AppColors.purple),
                        ),
                        TextSpan(
                          text: 'Asistente',
                          style: TextStyle(color: AppColors.turquoise),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30 * scale),
                Container(
                  width: 176 * scale,
                  height: 2,
                  color: AppColors.turquoise.withOpacity(0.45),
                ),
                SizedBox(height: 20 * scale),
                SizedBox(
                  width: 320 * scale,
                  child: Text(
                    'Aun no has aplicado para ser asistente.\n'
                    'Completa tu solicitud para comenzar el proceso\n'
                    'y poder activar tu cuenta de trabajo.',
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
                SizedBox(height: 36 * scale),
                Center(
                  child: SizedBox(
                    width: 310 * scale,
                    height: 250 * scale,
                    child: SvgPicture.asset(
                      'assets/images/undraw_my-documents-1.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 28 * scale),
                SizedBox(
                  width: double.infinity,
                  height: 58 * scale,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const AssistantIdentityVerificationScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.turquoise,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18 * scale),
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Empezar aplicacion'),
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
