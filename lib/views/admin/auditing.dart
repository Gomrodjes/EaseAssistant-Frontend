import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/measures.dart';
import '../../models/models.dart';
import '../../services/application_service.dart';
import '../../services/user_service.dart';
import 'auditing_review_screen.dart';

class Auditing extends StatefulWidget {
  const Auditing({super.key});

  @override
  State<Auditing> createState() => _AuditingState();
}

class _AuditingState extends State<Auditing> {
  final UserService _userService = UserService();
  final ApplicationService _applicationService = ApplicationService();

  bool _isLoading = true;
  String? _errorMessage;
  List<UserResponseDto> _usersForAudit = const [];

  @override
  void initState() {
    super.initState();
    _loadUsersForAudit();
  }

  @override
  void dispose() {
    _userService.dispose();
    _applicationService.dispose();
    super.dispose();
  }

  Future<void> _loadUsersForAudit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final usersResponse = await _userService.getAllUsers();
      final applicationsResponse = await _applicationService.getAllApplications();
      final users = usersResponse.data ?? <UserResponseDto>[];
      final applications = applicationsResponse.data ?? <ApplicationResponseDto>[];
      final pendingApplicationUserIds = applications
          .where((application) => application.state == StateApplication.pending)
          .map((application) => application.userId)
          .toSet();

      final filteredUsers = users.where((user) {
        final userId = user.id;

        return userId != null &&
            user.isActive &&
            user.isVerified &&
            !user.documentationVerified &&
            pendingApplicationUserIds.contains(userId);
      }).toList()
        ..sort(
          (first, second) => first.fullName.toLowerCase().compareTo(
                second.fullName.toLowerCase(),
              ),
        );

      if (!mounted) return;

      setState(() {
        _usersForAudit = filteredUsers;
        _isLoading = false;
      });
    } on UserServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } on ApplicationServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudieron cargar los usuarios.';
        _isLoading = false;
      });
    }
  }

  void _showUserDetails(UserResponseDto user) {
    Navigator.of(context)
        .push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => AuditingReviewScreen(user: user),
          ),
        )
        .then((shouldRefresh) {
          if (shouldRefresh == true && mounted) {
            _loadUsersForAudit();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Revision de cuentas'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navyBlue,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.turquoise,
        onRefresh: _loadUsersForAudit,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            18 * scale,
            14 * scale,
            18 * scale,
            28 * scale,
          ),
          children: [
            if (_isLoading)
              SizedBox(
                height: Measures.height(context) * 0.65,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.turquoise,
                  ),
                ),
              )
            else if (_errorMessage != null)
              _FeedbackCard(
                message: _errorMessage!,
                helperText: 'Desliza hacia abajo para volver a intentarlo.',
                scale: scale,
              )
            else if (_usersForAudit.isEmpty)
              _FeedbackCard(
                message: 'No hay asistentes pendientes de revision.',
                helperText:
                    'Solo se muestran usuarios activos y verificados, con application pendiente y documentationVerified en false.',
                scale: scale,
              )
            else
              ..._usersForAudit.map(
                (user) => Padding(
                  padding: EdgeInsets.only(bottom: 14 * scale),
                  child: _AuditUserCard(
                    user: user,
                    scale: scale,
                    onView: () => _showUserDetails(user),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AuditUserCard extends StatelessWidget {
  const _AuditUserCard({
    required this.user,
    required this.scale,
    required this.onView,
  });

  final UserResponseDto user;
  final double scale;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final minCardHeight = 70 * scale;

    return Container(
      constraints: BoxConstraints(minHeight: minCardHeight),
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 12 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22 * scale),
        border: Border.all(
          color: AppColors.navyBlue.withOpacity(0.45),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38 * scale,
            height: 38 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.navyBlue,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person_outline,
              color: AppColors.navyBlue,
              size: 24 * scale,
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revision de ${user.fullName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.navyBlue,
                    fontSize: 17 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * scale),
          IconButton(
            onPressed: onView,
            icon: Icon(
              Icons.remove_red_eye_outlined,
              color: AppColors.navyBlue,
              size: 28 * scale,
            ),
            tooltip: 'Ver usuario',
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.message,
    required this.helperText,
    required this.scale,
  });

  final String message;
  final String helperText;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 24 * scale),
      padding: EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFC),
        borderRadius: BorderRadius.circular(22 * scale),
        border: Border.all(
          color: AppColors.turquoise.withOpacity(0.35),
        ),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.navyBlue,
              fontSize: 16 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10 * scale),
          Text(
            helperText,
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
}
