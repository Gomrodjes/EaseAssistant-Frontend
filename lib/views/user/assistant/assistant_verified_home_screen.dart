import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/app_colors.dart';
import '../../../config/measures.dart';
import '../../../core/secure_storage.dart';
import '../../../models/booking_models.dart';
import '../../../models/category_models.dart';
import '../../../models/core/app_enums.dart';
import '../../../models/user_models.dart';
import '../../../models/user_service_assignment_models.dart';
import '../../../services/booking_service.dart';
import '../../../services/category_service.dart';
import '../../../services/user_service.dart';
import '../../../services/user_service_assignment_service.dart';
import '../profile.dart';

class AssistantVerifiedHomeScreen extends StatefulWidget {
  const AssistantVerifiedHomeScreen({super.key});

  @override
  State<AssistantVerifiedHomeScreen> createState() =>
      _AssistantVerifiedHomeScreenState();
}

class _AssistantVerifiedHomeScreenState
    extends State<AssistantVerifiedHomeScreen> {
  final UserService _userService = UserService();
  final CategoryService _categoryService = CategoryService();
  final BookingService _bookingService = BookingService();
  final UserServiceAssignmentService _assignmentService =
      UserServiceAssignmentService();

  bool _isLoading = true;
  String? _errorMessage;

  UserResponseDto? _currentUser;
  List<CategoryResponseDto> _categories = const <CategoryResponseDto>[];
  List<BookingResponseDto> _bookings = const <BookingResponseDto>[];
  List<UserServiceAssignmentResponseDto> _assignments =
      const <UserServiceAssignmentResponseDto>[];
  String? _selectedCategoryName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _userService.dispose();
    _categoryService.dispose();
    _bookingService.dispose();
    _assignmentService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) {
        throw const UserServiceException('No se encontro la sesion del usuario.');
      }

      final email = SecureStorage.getEmailFromToken(token).trim().toLowerCase();
      final usersResponse = await _userService.getAllUsers();
      final users = usersResponse.data ?? <UserResponseDto>[];

      UserResponseDto? currentUser;
      for (final user in users) {
        if (user.email.trim().toLowerCase() == email) {
          currentUser = user;
          break;
        }
      }

      if (currentUser == null || currentUser.id == null) {
        throw const UserServiceException(
          'No se pudo cargar el usuario autenticado.',
        );
      }

      final userId = currentUser.id!;
      final categoriesResponse = await _categoryService.getAllCategories();
      final bookingsResponse = await _bookingService.getBookingsByUser(userId);
      final assignmentsResponse = await _assignmentService.getAssignmentsByUser(
        userId,
      );

      final categories = (categoriesResponse.data ?? <CategoryResponseDto>[])
          .where((category) => category.active && category.name.trim().isNotEmpty)
          .toList()
        ..sort(
          (first, second) => first.name.toLowerCase().compareTo(
                second.name.toLowerCase(),
              ),
        );

      final bookings = (bookingsResponse.data ?? <BookingResponseDto>[])
          .where((booking) => booking.state != StateBooking.canceled)
          .toList()
        ..sort((first, second) {
          final firstDate = first.dateBooking ?? DateTime(2100);
          final secondDate = second.dateBooking ?? DateTime(2100);
          final dateComparison = firstDate.compareTo(secondDate);
          if (dateComparison != 0) {
            return dateComparison;
          }
          return (first.startTime ?? '').compareTo(second.startTime ?? '');
        });

      final assignments =
          (assignmentsResponse.data ?? <UserServiceAssignmentResponseDto>[])
              .where((assignment) => assignment.active)
              .toList();

      if (!mounted) return;

      setState(() {
        _currentUser = currentUser;
        _categories = categories;
        _bookings = bookings;
        _assignments = assignments;
        _isLoading = false;
      });
    } on UserServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } on CategoryServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } on BookingServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } on UserServiceAssignmentServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo cargar la pantalla del asistente.';
        _isLoading = false;
      });
    }
  }

  List<CategoryResponseDto> get _visibleCategories {
    if (_assignments.isEmpty) {
      return _categories;
    }

    final assignedServiceNames = _assignments
        .map((assignment) => _normalizeText(assignment.serviceName))
        .toSet();

    return _categories.where((category) {
      return category.serviceNames
          .map(_normalizeText)
          .any(assignedServiceNames.contains);
    }).toList();
  }

  List<BookingResponseDto> get _filteredBookings {
    if (_selectedCategoryName == null) {
      return _bookings;
    }

    CategoryResponseDto? selectedCategory;
    for (final category in _categories) {
      if (category.name.toLowerCase() == _selectedCategoryName!.toLowerCase()) {
        selectedCategory = category;
        break;
      }
    }

    if (selectedCategory == null) {
      return _bookings;
    }

    final selectedServiceNames = selectedCategory.serviceNames
        .map(_normalizeText)
        .toSet();

    final hasAssignedServiceInCategory = _assignments.any(
      (assignment) =>
          selectedServiceNames.contains(_normalizeText(assignment.serviceName)),
    );

    if (!hasAssignedServiceInCategory) {
      return const <BookingResponseDto>[];
    }

    return _bookings;
  }

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);
    final userName = (_currentUser?.fullName.trim().isNotEmpty ?? false)
        ? _currentUser!.fullName.trim()
        : 'Nombre usuario';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.turquoise,
          onRefresh: _loadData,
          child: _buildBody(context, scale, userName),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, double scale, String userName) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.turquoise),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24 * scale),
        children: [
          SizedBox(height: 100 * scale),
          _InfoMessageCard(
            title: 'No se pudo cargar la pantalla',
            message: _errorMessage!,
            actionLabel: 'Reintentar',
            onPressed: _loadData,
          ),
        ],
      );
    }

    final visibleCategories = _visibleCategories;
    final filteredBookings = _filteredBookings;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        20 * scale,
        16 * scale,
        20 * scale,
        28 * scale,
      ),
      children: [
        _TopProfileButton(
          userName: userName,
          scale: scale,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            );
          },
        ),
        SizedBox(height: 14 * scale),
        SvgPicture.asset(
          'assets/images/assistant_image_home-1.svg',
          height: 230 * scale,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 6 * scale),
        Text(
          'Buenos dias, ${_firstName(userName)}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28 * scale,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF6F8FAF),
          ),
        ),
        SizedBox(height: 18 * scale),
        if (visibleCategories.isNotEmpty)
          _CategoryFilterList(
            categories: visibleCategories,
            selectedCategoryName: _selectedCategoryName,
            scale: scale,
            onSelected: (categoryName) {
              setState(() {
                _selectedCategoryName =
                    _selectedCategoryName == categoryName ? null : categoryName;
              });
            },
          ),
        SizedBox(height: 20 * scale),
        Text(
          'Servicios contratados para hoy',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18 * scale,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF434343),
          ),
        ),
        SizedBox(height: 16 * scale),
        if (filteredBookings.isEmpty)
          _InfoMessageCard(
            title: _selectedCategoryName == null
                ? 'No hay reservas disponibles'
                : 'No hay reservas para esta categoria',
            message: _selectedCategoryName == null
                ? 'Cuando tengas reservas asociadas apareceran aqui.'
                : 'Prueba con otra categoria o quita el filtro.',
          )
        else
          ...filteredBookings.map(
            (booking) => Padding(
              padding: EdgeInsets.only(bottom: 14 * scale),
              child: _BookingCard(
                booking: booking,
                scale: scale,
                categoryName: _selectedCategoryName ?? _categoryLabelFallback(),
              ),
            ),
          ),
      ],
    );
  }

  String _categoryLabelFallback() {
    final visibleCategories = _visibleCategories;
    if (visibleCategories.isNotEmpty) {
      return visibleCategories.first.name;
    }
    return 'Limpieza';
  }

  String _firstName(String fullName) {
    final pieces = fullName.trim().split(RegExp(r'\s+'));
    if (pieces.isEmpty || pieces.first.isEmpty) {
      return 'Jesus';
    }
    return pieces.first;
  }

  String _normalizeText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('_', ' ');
  }
}

class _TopProfileButton extends StatelessWidget {
  const _TopProfileButton({
    required this.userName,
    required this.scale,
    required this.onTap,
  });

  final String userName;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE4E4E4),
      borderRadius: BorderRadius.circular(22 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(22 * scale),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 10 * scale,
            vertical: 8 * scale,
          ),
          child: Row(
            children: [
              Container(
                width: 28 * scale,
                height: 28 * scale,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_circle_outlined,
                  color: AppColors.turquoise,
                  size: 22 * scale,
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4A4A4A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterList extends StatelessWidget {
  const _CategoryFilterList({
    required this.categories,
    required this.selectedCategoryName,
    required this.scale,
    required this.onSelected,
  });

  final List<CategoryResponseDto> categories;
  final String? selectedCategoryName;
  final double scale;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 94 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 14 * scale),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategoryName?.toLowerCase() ==
              category.name.toLowerCase();

          return GestureDetector(
            onTap: () => onSelected(category.name),
            child: SizedBox(
              width: 64 * scale,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 56 * scale,
                    height: 56 * scale,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF8DB0D3)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(10 * scale),
                    child: _SafeCategoryIcon(
                      assetPath: _safeCategoryAssetPathFromName(category.name),
                      scale: scale,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Text(
                    category.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10 * scale,
                      color: const Color(0xFF616161),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.scale,
    required this.categoryName,
  });

  final BookingResponseDto booking;
  final double scale;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF8DB0D3),
        borderRadius: BorderRadius.circular(20 * scale),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 12 * scale,
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_circle_outlined,
            color: AppColors.navyBlue,
            size: 32 * scale,
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reserva #${booking.id ?? '-'}',
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1B3D5D),
                  ),
                ),
                SizedBox(height: 6 * scale),
                _BookingMetaRow(
                  icon: Icons.access_time_outlined,
                  text: _timeRangeLabel(booking),
                  scale: scale,
                ),
                SizedBox(height: 3 * scale),
                _BookingMetaRow(
                  icon: Icons.calendar_today_outlined,
                  text: _dateLabel(booking.dateBooking),
                  scale: scale,
                ),
              ],
            ),
          ),
          SizedBox(width: 10 * scale),
          SizedBox(
            width: 56 * scale,
            child: Column(
              children: [
                _SafeCategoryIcon(
                  assetPath: _safeCategoryAssetPathFromName(categoryName),
                  scale: scale,
                  width: 28 * scale,
                  height: 28 * scale,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 4 * scale),
                Text(
                  categoryName,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10 * scale,
                    color: const Color(0xFF1B5A8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime? date) {
    if (date == null) {
      return 'Fecha pendiente';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _timeRangeLabel(BookingResponseDto booking) {
    final startTime = _shortTime(booking.startTime);
    final endTime = _shortTime(booking.endTime);
    return '$startTime - $endTime';
  }

  String _shortTime(String? value) {
    if (value == null || value.isEmpty) {
      return '--:--';
    }
    return value.length >= 5 ? value.substring(0, 5) : value;
  }
}

class _BookingMetaRow extends StatelessWidget {
  const _BookingMetaRow({
    required this.icon,
    required this.text,
    required this.scale,
  });

  final IconData icon;
  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 12 * scale,
          color: AppColors.navyBlue,
        ),
        SizedBox(width: 5 * scale),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12 * scale,
              color: const Color(0xFF3D6E94),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoMessageCard extends StatelessWidget {
  const _InfoMessageCard({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return Container(
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FB),
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(color: const Color(0xFFD7E5F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w700,
              color: AppColors.navyBlue,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            message,
            style: TextStyle(
              fontSize: 13 * scale,
              color: const Color(0xFF5E6F7E),
            ),
          ),
          if (actionLabel != null && onPressed != null) ...[
            SizedBox(height: 14 * scale),
            SizedBox(
              height: 40 * scale,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.turquoise,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SafeCategoryIcon extends StatefulWidget {
  const _SafeCategoryIcon({
    required this.assetPath,
    required this.scale,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final String assetPath;
  final double scale;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  State<_SafeCategoryIcon> createState() => _SafeCategoryIconState();
}

class _SafeCategoryIconState extends State<_SafeCategoryIcon> {
  bool _assetExists = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAsset();
  }

  @override
  void didUpdateWidget(covariant _SafeCategoryIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _checkAsset();
    }
  }

  Future<void> _checkAsset() async {
    try {
      await DefaultAssetBundle.of(context).loadString(widget.assetPath);
      if (!mounted) return;
      setState(() {
        _assetExists = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _assetExists = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_assetExists) {
      return Icon(
        Icons.miscellaneous_services_outlined,
        color: AppColors.navyBlue,
        size: widget.width ?? widget.height ?? (28 * widget.scale),
      );
    }

    return SvgPicture.asset(
      widget.assetPath,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}

String _safeCategoryAssetPathFromName(String categoryName) {
  final normalizedCategoryName = categoryName
      .trim()
      .toLowerCase()
      .replaceAll('ñ', 'n')
      .replaceAll('Ã±', 'n');

  switch (normalizedCategoryName) {
    case 'limpieza':
      return 'assets/images/categories/limpieza.svg';
    case 'cocina':
      return 'assets/images/categories/cocina.svg';
    case 'compania':
      return 'assets/images/categories/compania.svg';
    case 'cuidado personal':
      return 'assets/images/categories/cuidado_personal.svg';
    case 'tecnologia':
      return 'assets/images/categories/tecnologia.svg';
    case 'transporte':
      return 'assets/images/categories/transporte.svg';
    default:
      return 'assets/images/categories/limpieza.svg';
  }
}