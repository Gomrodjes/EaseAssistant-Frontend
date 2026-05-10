import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/measures.dart';
import '../../core/secure_storage.dart';
import '../../models/models.dart';
import '../../services/user_service.dart';
import '../auth/login_screen.dart';
import 'add_services.dart';
import 'auditing.dart';
import 'user_management.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final UserService _userService = UserService();

  bool _isLoading = true;
  int _femaleCount = 0;
  int _maleCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGenderStats();
  }

  @override
  void dispose() {
    _userService.dispose();
    super.dispose();
  }

  Future<void> _loadGenderStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _userService.getAllUsers();
      final users = response.data ?? <UserResponseDto>[];

      var femaleCount = 0;
      var maleCount = 0;

      for (final user in users) {
        switch (user.gender) {
          case Gender.female:
            femaleCount++;
            break;
          case Gender.male:
            maleCount++;
            break;
          case Gender.other:
          case null:
            break;
        }
      }

      if (!mounted) return;

      setState(() {
        _femaleCount = femaleCount;
        _maleCount = maleCount;
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
        _errorMessage = 'No se pudo cargar la grafica.';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await SecureStorage.deleteToken();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _openScreen(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.turquoise,
          onRefresh: _loadGenderStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              20 * scale,
              18 * scale,
              20 * scale,
              28 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdminHeader(
                  scale: scale,
                  onLogout: _logout,
                ),
                SizedBox(height: 18 * scale),
                _AdminActionButton(
                  label: 'Gestion de usuarios',
                  scale: scale,
                  onTap: () => _openScreen(const UserManagement()),
                ),
                SizedBox(height: 14 * scale),
                _AdminActionButton(
                  label: 'Revision de cuentas',
                  scale: scale,
                  onTap: () => _openScreen(const Auditing()),
                ),
                SizedBox(height: 14 * scale),
                _AdminActionButton(
                  label: 'Anadir Servicios',
                  scale: scale,
                  onTap: () => _openScreen(const AddServices()),
                ),
                SizedBox(height: 20 * scale),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: AppColors.turquoise.withOpacity(0.65),
                ),
                SizedBox(height: 16 * scale),
                Center(
                  child: Text(
                    'Usuarios por genero',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.navyBlue,
                      fontSize: 22 * scale,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(height: 18 * scale),
                _GenderChartCard(
                  scale: scale,
                  femaleCount: _femaleCount,
                  maleCount: _maleCount,
                  isLoading: _isLoading,
                  errorMessage: _errorMessage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({
    required this.scale,
    required this.onLogout,
  });

  final double scale;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 24 * scale,
        vertical: 22 * scale,
      ),
      decoration: BoxDecoration(
        color: AppColors.navyBlue,
        borderRadius: BorderRadius.circular(28 * scale),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Panel\nde Admin',
              style: TextStyle(
                color: const Color(0xFF9AE6EB),
                fontSize: 25 * scale,
                fontWeight: FontWeight.w800,
                height: 1.18,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              onLogout();
            },
            icon: Icon(
              Icons.settings,
              color: Colors.white,
              size: 42 * scale,
            ),
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
    );
  }
}

class _AdminActionButton extends StatelessWidget {
  const _AdminActionButton({
    required this.label,
    required this.scale,
    required this.onTap,
  });

  final String label;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: 16 * scale,
            vertical: 16 * scale,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18 * scale),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF9AE6EB),
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 28 * scale,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderChartCard extends StatelessWidget {
  const _GenderChartCard({
    required this.scale,
    required this.femaleCount,
    required this.maleCount,
    required this.isLoading,
    required this.errorMessage,
  });

  final double scale;
  final int femaleCount;
  final int maleCount;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 260 * scale,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.turquoise),
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(18 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFFF5FAFB),
          borderRadius: BorderRadius.circular(22 * scale),
        ),
        child: Column(
          children: [
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navyBlue,
                fontSize: 15 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12 * scale),
            Text(
              'Desliza hacia abajo para volver a intentarlo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13 * scale,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        12 * scale,
        8 * scale,
        12 * scale,
        18 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * scale),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 230 * scale,
            child: _GenderBarChart(
              femaleCount: femaleCount,
              maleCount: maleCount,
              scale: scale,
            ),
          ),
          SizedBox(height: 12 * scale),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 18 * scale,
            runSpacing: 8 * scale,
            children: [
              _ChartLegend(
                color: AppColors.turquoise,
                label: 'Mujeres: $femaleCount',
                scale: scale,
              ),
              _ChartLegend(
                color: AppColors.navyBlue,
                label: 'Hombres: $maleCount',
                scale: scale,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenderBarChart extends StatelessWidget {
  const _GenderBarChart({
    required this.femaleCount,
    required this.maleCount,
    required this.scale,
  });

  final int femaleCount;
  final int maleCount;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final maxValue = [femaleCount, maleCount, 1].reduce(
      (value, element) => value > element ? value : element,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 34 * scale,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (index) {
              final value = ((maxValue * (3 - index)) / 3).round();
              return Text(
                '$value',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w600,
                ),
              );
            }),
          ),
        ),
        SizedBox(width: 8 * scale),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (_) {
                        return Container(
                          height: 1,
                          color: AppColors.turquoise.withOpacity(0.25),
                        );
                      }),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _ChartBar(
                            label: 'Mujeres',
                            value: femaleCount,
                            maxValue: maxValue,
                            color: AppColors.turquoise,
                            scale: scale,
                          ),
                          _ChartBar(
                            label: 'Hombres',
                            value: maleCount,
                            maxValue: maxValue,
                            color: AppColors.navyBlue,
                            scale: scale,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6 * scale),
              Container(
                width: double.infinity,
                height: 2,
                color: AppColors.turquoise.withOpacity(0.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartBar extends StatelessWidget {
  const _ChartBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.scale,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final heightFactor = maxValue == 0 ? 0.0 : value / maxValue;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 14 * scale,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8 * scale),
        Container(
          width: 72 * scale,
          height: 150 * scale,
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 52 * scale,
            height: (150 * scale) * heightFactor.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(18 * scale),
              ),
            ),
          ),
        ),
        SizedBox(height: 12 * scale),
        Text(
          label,
          style: TextStyle(
            color: AppColors.navyBlue,
            fontSize: 13 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({
    required this.color,
    required this.label,
    required this.scale,
  });

  final Color color;
  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12 * scale,
          height: 12 * scale,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3 * scale),
          ),
        ),
        SizedBox(width: 6 * scale),
        Text(
          label,
          style: TextStyle(
            color: AppColors.navyBlue,
            fontSize: 13 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
