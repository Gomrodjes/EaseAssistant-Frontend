import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/measures.dart';
import '../../core/secure_storage.dart';
import '../../models/models.dart';
import '../../services/notification_service.dart';
import '../../services/user_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  UserResponseDto? _currentUser;
  bool _isLoading = true;
  bool _isDeletingAccount = false;
  bool _isLoggingOut = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _userService.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) {
        throw const UserServiceException('No se encontro sesion activa.');
      }

      final email = SecureStorage.getEmailFromToken(token).trim().toLowerCase();
      final response = await _userService.getAllUsers();

      UserResponseDto? currentUser;
      for (final user in response.data ?? <UserResponseDto>[]) {
        if (user.email.trim().toLowerCase() == email) {
          currentUser = user;
          break;
        }
      }

      if (currentUser == null) {
        throw const UserServiceException(
          'No se pudo cargar la informacion del perfil.',
        );
      }

      if (!mounted) return;
      setState(() {
        _currentUser = currentUser;
        _isLoading = false;
      });
    } on UserServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo cargar tu perfil.';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut || _isDeletingAccount) return;

    setState(() {
      _isLoggingOut = true;
    });

    await NotificationService.instance.unregisterDeviceFromBackend();
    await SecureStorage.deleteToken();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _confirmDeleteAccount() async {
    if (_isDeletingAccount || _isLoggingOut || _currentUser?.id == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar cuenta'),
          content: const Text(
            'Esta accion eliminara tu cuenta de forma permanente. Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() {
      _isDeletingAccount = true;
    });

    try {
      await NotificationService.instance.unregisterDeviceFromBackend();
      await _userService.deleteUser(_currentUser!.id!);
      await SecureStorage.deleteToken();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on UserServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar la cuenta en este momento.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);
    final user = _currentUser;
    final displayName =
        user?.fullName.trim().isNotEmpty == true
            ? user!.fullName.trim()
            : 'Usuario';
    final nameParts =
        displayName.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    final firstLine = nameParts.isEmpty ? 'Usuario' : nameParts.first;
    final secondLine =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.turquoise,
          onRefresh: _loadUser,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              0,
              18 * scale,
              0,
              24 * scale,
            ),
            child: _buildBody(
              context: context,
              scale: scale,
              firstLine: firstLine,
              secondLine: secondLine,
              user: user,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required double scale,
    required String firstLine,
    required String secondLine,
    required UserResponseDto? user,
  }) {
    if (_isLoading) {
      return SizedBox(
        height: Measures.height(context) * 0.75,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.turquoise),
        ),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: Measures.height(context) * 0.75,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28 * scale),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.navyBlue,
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12 * scale),
                Text(
                  'Desliza hacia abajo para volver a intentarlo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14 * scale,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16 * scale),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 18 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstLine,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (secondLine.isNotEmpty)
                        Text(
                          secondLine,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24 * scale,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 60 * scale,
                height: 60 * scale,
                margin: EdgeInsets.only(top: 8 * scale, right: 20 * scale),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.navyBlue,
                    width: 3 * scale,
                  ),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: AppColors.navyBlue,
                  size: 38 * scale,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24 * scale),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15 * scale),
          child: Row(
            children: [
              Expanded(
                child: _InfoCard(
                  scale: scale,
                  icon: Icons.star_border_rounded,
                  value:
                      '${user?.averageRating.toStringAsFixed(1) ?? '0.0'}/5',
                  label: 'Experiencia',
                ),
              ),
              SizedBox(width: 18 * scale),
              Expanded(
                child: _InfoCard(
                  scale: scale,
                  icon: Icons.people_outline_rounded,
                  value: '${user?.numberOfReviews ?? 0}',
                  label: 'Opiniones',
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 22 * scale),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15 * scale),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 16 * scale,
              vertical: 14 * scale,
            ),
            decoration: BoxDecoration(
              color: AppColors.turquoise.withOpacity(0.78),
              borderRadius: BorderRadius.circular(18 * scale),
            ),
            child: Row(
              children: [
                Container(
                  width: 48 * scale,
                  height: 48 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF73D5D3),
                    borderRadius: BorderRadius.circular(12 * scale),
                  ),
                  child: Icon(
                    Icons.volunteer_activism_outlined,
                    color: Colors.white,
                    size: 28 * scale,
                  ),
                ),
                SizedBox(width: 16 * scale),
                Expanded(
                  child: Text(
                    'Nunca estas solo:\nestamos contigo.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 36 * scale),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            22 * scale,
            20 * scale,
            22 * scale,
            34 * scale,
          ),
          decoration: BoxDecoration(
            color: AppColors.turquoise.withOpacity(0.8),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28 * scale),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perfil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 16 * scale),
              _ProfileActionRow(
                scale: scale,
                icon: Icons.person_outline,
                label: 'Editar Cuenta',
              ),
              _divider(scale),
              _ProfileActionRow(
                scale: scale,
                icon: Icons.translate_rounded,
                label: 'Idioma',
              ),
              _divider(scale),
              _ProfileActionRow(
                scale: scale,
                icon: Icons.help_outline_rounded,
                label: 'Preguntas frecuentes',
              ),
              _divider(scale),
              _ProfileActionRow(
                scale: scale,
                icon: Icons.notifications_none_rounded,
                label: 'Notificaciones',
              ),
              _divider(scale),
              _ProfileActionRow(
                scale: scale,
                icon: Icons.delete_outline_rounded,
                label: 'Eliminar Cuenta',
                onTap: _confirmDeleteAccount,
                isBusy: _isDeletingAccount,
              ),
              _divider(scale),
              _ProfileActionRow(
                scale: scale,
                icon: Icons.logout_rounded,
                label: 'Cerrar Sesion',
                onTap: _logout,
                isBusy: _isLoggingOut,
              ),
              SizedBox(height: 26 * scale),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Version 0.0.1',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6 * scale),
      child: Container(
        width: double.infinity,
        height: 1,
        color: Colors.white.withOpacity(0.75),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.scale,
    required this.icon,
    required this.value,
    required this.label,
  });

  final double scale;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 18 * scale,
      ),
      decoration: BoxDecoration(
        color: AppColors.turquoise.withOpacity(0.8),
        borderRadius: BorderRadius.circular(26 * scale),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28 * scale),
              SizedBox(width: 14 * scale),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 10 * scale),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionRow extends StatelessWidget {
  const _ProfileActionRow({
    required this.scale,
    required this.icon,
    required this.label,
    this.onTap,
    this.isBusy = false,
  });

  final double scale;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Icon(icon, color: Colors.white, size: 25 * scale),
        SizedBox(width: 16 * scale),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isBusy)
          SizedBox(
            width: 18 * scale,
            height: 18 * scale,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        else
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white,
            size: 26 * scale,
          ),
      ],
    );

    if (onTap == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 6 * scale),
        child: row,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(12 * scale),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6 * scale),
          child: row,
        ),
      ),
    );
  }
}
