import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../config/app_colors.dart';
import '../../config/measures.dart';
import '../../models/models.dart';
import '../../services/user_service.dart';
import 'user_status_screen.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _hiddenUserIds = <int>{};

  List<UserResponseDto> _users = <UserResponseDto>[];
  bool _isLoading = true;
  String? _errorMessage;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _userService.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _userService.getAllUsers();
      final users = (response.data ?? <UserResponseDto>[])
          .where((user) => user.role != UserRole.admin)
          .toList()
        ..sort((first, second) {
          if (first.isActive != second.isActive) {
            return first.isActive ? -1 : 1;
          }

          return first.fullName.toLowerCase().compareTo(
                second.fullName.toLowerCase(),
              );
        });
      if (!mounted) return;

      setState(() {
        _users = users;
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
        _errorMessage = 'No se pudieron cargar los usuarios.';
        _isLoading = false;
      });
    }
  }

  List<UserResponseDto> get _filteredUsers {
    final normalizedQuery = _query.trim().toLowerCase();

    return _users.where((user) {
      final userId = user.id;
      if (userId != null && _hiddenUserIds.contains(userId)) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      return user.fullName.toLowerCase().contains(normalizedQuery) ||
          user.email.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  void _removeUser(UserResponseDto user) {
    final userId = user.id;
    if (userId != null) {
      setState(() {
        _hiddenUserIds.add(userId);
      });
    } else {
      setState(() {
        _users = _users.where((item) => item != user).toList();
      });
    }
  }

  Future<bool> _confirmDelete(UserResponseDto user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final scale = Measures.scale(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20 * scale),
          ),
          title: Text(
            'Confirmar eliminacion',
            style: TextStyle(
              color: AppColors.navyBlue,
              fontSize: 18 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Seguro que quieres eliminar este usuario?',
            style: TextStyle(
              color: AppColors.navyBlue.withOpacity(0.8),
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.navyBlue),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF2B1F),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _showUserDetails(UserResponseDto user) async {
    final updatedUser = await Navigator.of(context).push<UserResponseDto>(
      MaterialPageRoute(
        builder: (_) => UserStatusScreen(user: user),
      ),
    );

    if (!mounted || updatedUser == null) {
      return;
    }

    setState(() {
      _users = _users
          .map((item) => item.id == updatedUser.id ? updatedUser : item)
          .toList()
        ..sort((first, second) {
          if (first.isActive != second.isActive) {
            return first.isActive ? -1 : 1;
          }

          return first.fullName.toLowerCase().compareTo(
                second.fullName.toLowerCase(),
              );
        });
    });
  }

  String _formatRoleShort(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.client:
        return 'Cliente';
      case UserRole.assistant:
        return 'Asistente';
      case null:
        return 'Sin rol';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);
    final filteredUsers = _filteredUsers;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Gestion de usuarios'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navyBlue,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.turquoise,
        onRefresh: _loadUsers,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            24 * scale,
            14 * scale,
            24 * scale,
            24 * scale,
          ),
          children: [
            _SearchBar(
              controller: _searchController,
              scale: scale,
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
            ),
            SizedBox(height: 18 * scale),
            if (_isLoading)
              Padding(
                padding: EdgeInsets.only(top: 42 * scale),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.turquoise,
                  ),
                ),
              )
            else if (_errorMessage != null)
              _StateCard(
                scale: scale,
                title: _errorMessage!,
                subtitle: 'Desliza hacia abajo para volver a intentarlo.',
              )
            else if (filteredUsers.isEmpty)
              _StateCard(
                scale: scale,
                title: 'No hay usuarios para mostrar.',
                subtitle: _query.isEmpty
                    ? 'Cuando existan registros apareceran aqui.'
                    : 'Prueba con otro nombre o correo.',
              )
            else
              ...filteredUsers.map(
                (user) => Padding(
                  padding: EdgeInsets.only(bottom: 14 * scale),
                  child: _UserCard(
                    user: user,
                    scale: scale,
                    roleLabel: _formatRoleShort(user.role),
                    onView: () => _showUserDetails(user),
                    onDelete: () async {
                      final shouldDelete = await _confirmDelete(user);
                      if (!shouldDelete || !mounted) {
                        return;
                      }
                      _removeUser(user);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.scale,
    required this.onChanged,
  });

  final TextEditingController controller;
  final double scale;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 34 * scale,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: AppColors.navyBlue,
              style: TextStyle(
                color: AppColors.navyBlue,
                fontSize: 13 * scale,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12 * scale,
                  vertical: 8 * scale,
                ),
                hintText: 'Buscar usuario',
                hintStyle: TextStyle(
                  color: AppColors.navyBlue.withOpacity(0.42),
                  fontSize: 12 * scale,
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8 * scale),
                  borderSide: BorderSide(
                    color: AppColors.navyBlue.withOpacity(0.55),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8 * scale),
                  borderSide: const BorderSide(
                    color: AppColors.navyBlue,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 8 * scale),
        Icon(
          Icons.search_rounded,
          color: AppColors.navyBlue,
          size: 20 * scale,
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.scale,
    required this.roleLabel,
    required this.onView,
    required this.onDelete,
  });

  final UserResponseDto user;
  final double scale;
  final String roleLabel;
  final VoidCallback onView;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final fullName =
        user.fullName.isEmpty ? 'Nombre de usuario' : user.fullName;
    final email = user.email.isEmpty ? 'email' : user.email;
    final cardHeight = 54 * scale;

    final borderRadius = BorderRadius.circular(22 * scale);

    return Container(
      constraints: BoxConstraints(minHeight: cardHeight),
      decoration: BoxDecoration(
        color: const Color(0xFFFF2B1F),
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Slidable(
          key: ValueKey(user.id ?? '${user.email}-$fullName'),
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.23,
            children: [
              CustomSlidableAction(
                onPressed: (_) => onDelete(),
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                child: Center(
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                    size: 20 * scale,
                  ),
                ),
              ),
            ],
          ),
          child: Container(
            constraints: BoxConstraints(minHeight: cardHeight),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: Colors.white,
              border: Border.all(
                color: AppColors.navyBlue.withOpacity(0.55),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scale,
              vertical: 8 * scale,
            ),
            child: Row(
              children: [
                Container(
                  width: 24 * scale,
                  height: 24 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.navyBlue, width: 1.4),
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.navyBlue,
                    size: 16 * scale,
                  ),
                ),
                SizedBox(width: 8 * scale),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.navyBlue,
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 1 * scale),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.navyBlue.withOpacity(0.45),
                          fontSize: 10 * scale,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 3 * scale),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7 * scale,
                                vertical: 2 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF5FB),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                roleLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.navyBlue,
                                  fontSize: 9 * scale,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 6 * scale),
                          Icon(
                            user.isActive
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: user.isActive
                                ? const Color(0xFF1FAF5A)
                                : const Color(0xFFFF2B1F),
                            size: 13 * scale,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onView,
                  child: Padding(
                    padding: EdgeInsets.all(4 * scale),
                    child: Icon(
                      Icons.remove_red_eye_outlined,
                      color: AppColors.navyBlue,
                      size: 18 * scale,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.scale,
    required this.title,
    required this.subtitle,
  });

  final double scale;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 18 * scale,
        vertical: 18 * scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFD),
        borderRadius: BorderRadius.circular(22 * scale),
        border: Border.all(
          color: AppColors.navyBlue.withOpacity(0.14),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.navyBlue,
              fontSize: 15 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.navyBlue.withOpacity(0.58),
              fontSize: 12 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
