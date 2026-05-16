import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/measures.dart';
import '../../models/models.dart';
import '../../services/user_service.dart';

class UserStatusScreen extends StatefulWidget {
  const UserStatusScreen({
    super.key,
    required this.user,
  });

  final UserResponseDto user;

  @override
  State<UserStatusScreen> createState() => _UserStatusScreenState();
}

class _UserStatusScreenState extends State<UserStatusScreen> {
  final UserService _userService = UserService();

  late UserResponseDto _user;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  @override
  void dispose() {
    _userService.dispose();
    super.dispose();
  }

  Future<void> _toggleUserStatus() async {
    final userId = _user.id;
    if (userId == null || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final targetIsActive = !_user.isActive;

    try {
      final response = await _userService.updateUserActiveStatus(
        userId,
        targetIsActive,
      );
      if (!mounted) return;

      setState(() {
        _user = response.data ?? _copyUserWith(isActive: targetIsActive);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            targetIsActive
                ? 'Usuario activado correctamente.'
                : 'Usuario desactivado correctamente.',
          ),
          backgroundColor: targetIsActive
              ? const Color(0xFF10D510)
              : const Color(0xFFFF1A12),
        ),
      );
    } on UserServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFFF2B1F),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar el estado del usuario.'),
          backgroundColor: Color(0xFFFF2B1F),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  UserResponseDto _copyUserWith({
    required bool isActive,
  }) {
    return UserResponseDto(
      id: _user.id,
      email: _user.email,
      fullName: _user.fullName,
      dateOfBirth: _user.dateOfBirth,
      gender: _user.gender,
      nationality: _user.nationality,
      biography: _user.biography,
      phoneNumber: _user.phoneNumber,
      role: _user.role,
      isActive: isActive,
      isVerified: _user.isVerified,
      documentationVerified: _user.documentationVerified,
      numberOfReviews: _user.numberOfReviews,
      averageRating: _user.averageRating,
    );
  }

  String _formatRole(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.client:
        return 'Usuario';
      case UserRole.assistant:
        return 'Trabajador';
      case null:
        return 'Sin rol';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);
    final actionLabel = _user.isActive ? 'Desactivar' : 'Activar';
    final actionColor = _user.isActive
        ? const Color(0xFFFF1A12)
        : const Color(0xFF10D510);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 18 * scale,
              vertical: 24 * scale,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 320 * scale),
              child: Column(
                children: [
                  Container(
                    width: 70 * scale,
                    height: 70 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.navyBlue,
                        width: 2.2 * scale,
                      ),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.navyBlue,
                      size: 44 * scale,
                    ),
                  ),
                  SizedBox(height: 14 * scale),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      12 * scale,
                      12 * scale,
                      12 * scale,
                      18 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.navyBlue,
                      borderRadius: BorderRadius.circular(18 * scale),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Datos del usuario',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 14 * scale),
                        _InfoPill(
                          value: _user.fullName.isEmpty
                              ? 'Sin nombre registrado'
                              : _user.fullName,
                          scale: scale,
                        ),
                        SizedBox(height: 10 * scale),
                        _InfoPill(
                          value: _user.email.isEmpty
                              ? 'Sin correo registrado'
                              : _user.email,
                          scale: scale,
                        ),
                        SizedBox(height: 10 * scale),
                        _InfoPill(
                          value: _user.phoneNumber.isEmpty
                              ? 'Sin telefono registrado'
                              : _user.phoneNumber,
                          scale: scale,
                        ),
                        SizedBox(height: 10 * scale),
                        _InfoPill(
                          value: (_user.nationality?.isNotEmpty ?? false)
                              ? _user.nationality!
                              : 'Sin nacionalidad',
                          scale: scale,
                        ),
                        SizedBox(height: 10 * scale),
                        _InfoPill(
                          value: _formatRole(_user.role),
                          scale: scale,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20 * scale),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _toggleUserStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: actionColor,
                        disabledBackgroundColor: actionColor.withOpacity(0.55),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10 * scale),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10 * scale),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 18 * scale,
                              height: 18 * scale,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              actionLabel,
                              style: TextStyle(
                                fontSize: 13 * scale,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 10 * scale),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_user),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10 * scale),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10 * scale),
                      ),
                      child: Text(
                        'Volver',
                        style: TextStyle(
                          fontSize: 13 * scale,
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
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.value,
    required this.scale,
  });

  final String value;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 6 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.navyBlue,
          fontSize: 12 * scale,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
