import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class UserManagement extends StatelessWidget {
  const UserManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de usuarios'),
        backgroundColor: AppColors.navyBlue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Pantalla de gestion de usuarios',
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
