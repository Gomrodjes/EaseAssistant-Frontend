import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class Auditing extends StatelessWidget {
  const Auditing({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revision de cuentas'),
        backgroundColor: AppColors.navyBlue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Pantalla de revision de cuentas',
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
