import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';

class AssistantVerifiedHomeScreen extends StatelessWidget {
  const AssistantVerifiedHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Asistente'),
        backgroundColor: AppColors.turquoise,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Panel Asistente',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.turquoise,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Has iniciado sesion como asistente.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
