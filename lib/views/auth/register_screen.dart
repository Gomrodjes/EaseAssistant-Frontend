import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/measures.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.turquoise),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24 * scale),
          child: Text(
            'Register Screen',
            style: TextStyle(
              color: AppColors.turquoise,
              fontSize: 28 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
