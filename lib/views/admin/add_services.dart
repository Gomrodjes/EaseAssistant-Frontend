import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class AddServices extends StatelessWidget {
  const AddServices({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anadir servicios'),
        backgroundColor: AppColors.navyBlue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Pantalla para anadir servicios',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navyBlue,
          ),
        ),
      ),
    );
  }
}
