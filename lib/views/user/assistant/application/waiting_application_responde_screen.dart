import 'package:flutter/material.dart';

import '../../../../config/app_colors.dart';

class WaitingApplicationRespondeScreen extends StatelessWidget {
  const WaitingApplicationRespondeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de espera'),
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
                'Panel Aplicacion de espera',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.turquoise,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Esperando a la respuesta del admin.',
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