import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/app_colors.dart';
import '../../../config/measures.dart';
import '../../../core/secure_storage.dart';
import '../../../models/models.dart';
import '../../../services/address_service.dart';
import '../../../services/category_service.dart';
import '../../../services/job_service.dart';
import '../../../services/user_service.dart';
import '../../../services/user_service_assignment_service.dart';
import 'address_form_screen.dart';
import 'service_payment_summary_screen.dart';

class ConfirmServiceScreen extends StatefulWidget {
  const ConfirmServiceScreen({
    super.key,
    required this.assistant,
    this.initialCategoryName,
  });

  final UserResponseDto assistant;
  final String? initialCategoryName;

  @override
  State<ConfirmServiceScreen> createState() => _ConfirmServiceScreenState();
}

class _ConfirmServiceScreenState extends State<ConfirmServiceScreen> {
  final CategoryService _categoryService = CategoryService();
  final JobService _jobService = JobService();
  final AddressService _addressService = AddressService();
  final UserService _userService = UserService();
  final UserServiceAssignmentService _assignmentService =
      UserServiceAssignmentService();
  final TextEditingController _noteController = TextEditingController();

  bool _isLoading = true;
  bool _isOpeningAddress = false;
  String? _errorMessage;

  UserResponseDto? _currentUser;
  List<CategoryResponseDto> _categories = const <CategoryResponseDto>[];
  List<JobResponseDto> _assistantJobs = const <JobResponseDto>[];
  List<AddressResponseDto> _addresses = const <AddressResponseDto>[];

  CategoryResponseDto? _selectedCategory;
  JobResponseDto? _selectedJob;
  AddressResponseDto? _selectedAddress;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _categoryService.dispose();
    _jobService.dispose();
    _addressService.dispose();
    _userService.dispose();
    _assignmentService.dispose();
    _noteController.dispose();
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
      UserResponseDto? currentUser;
      for (final user in usersResponse.data ?? <UserResponseDto>[]) {
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

      final categoriesResponse = await _categoryService.getAllCategories();
      final jobsResponse = await _jobService.getAllJobs();
      final addressesResponse = await _addressService.getAddressesByUser(
        currentUser.id!,
      );
      final assignmentsResponse = await _assignmentService.getAssignmentsByUser(
        widget.assistant.id ?? 0,
      );

      final activeAssignments = (assignmentsResponse.data ??
              <UserServiceAssignmentResponseDto>[])
          .where((assignment) => assignment.active)
          .toList();

      final assistantJobs = (jobsResponse.data ?? <JobResponseDto>[])
          .where(
            (job) =>
                job.name.trim().isNotEmpty &&
                activeAssignments.any(
                  (assignment) => _matchesCategoryAssignment(
                    job.categoryName,
                    assignment,
                  ),
                ),
          )
          .toList()
        ..sort(
          (first, second) => first.name.toLowerCase().compareTo(
                second.name.toLowerCase(),
              ),
        );

      final categories = (categoriesResponse.data ?? <CategoryResponseDto>[])
          .where(
            (category) =>
                category.active &&
                activeAssignments.any(
                  (assignment) => _matchesCategoryAssignment(
                    category.name,
                    assignment,
                  ),
                ),
          )
          .toList()
        ..sort(
          (first, second) => first.name.toLowerCase().compareTo(
                second.name.toLowerCase(),
              ),
        );

      final addresses = (addressesResponse.data ?? <AddressResponseDto>[])
          .toList()
        ..sort((first, second) {
          if (first.isPrimary == second.isPrimary) {
            return 0;
          }
          return first.isPrimary ? -1 : 1;
        });

      final selectedCategory = _resolveInitialCategory(categories);
      final selectedJob = _firstJobForCategory(
        assistantJobs,
        selectedCategory?.name,
      );

      if (!mounted) return;

      setState(() {
        _currentUser = currentUser;
        _categories = categories;
        _assistantJobs = assistantJobs;
        _addresses = addresses;
        _selectedCategory = selectedCategory;
        _selectedJob = selectedJob;
        _selectedAddress = addresses.isEmpty ? null : addresses.first;
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
    } on JobServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } on AddressException catch (e) {
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
        _errorMessage = 'No se pudo preparar la reserva.';
        _isLoading = false;
      });
    }
  }

  CategoryResponseDto? _resolveInitialCategory(
    List<CategoryResponseDto> categories,
  ) {
    if (categories.isEmpty) {
      return null;
    }

    if (widget.initialCategoryName == null ||
        widget.initialCategoryName!.trim().isEmpty) {
      return categories.first;
    }

    for (final category in categories) {
      if (_normalizeText(category.name) ==
          _normalizeText(widget.initialCategoryName!)) {
        return category;
      }
    }

    return categories.first;
  }

  List<JobResponseDto> get _visibleJobs {
    final categoryName = _selectedCategory?.name;
    if (categoryName == null) {
      return const <JobResponseDto>[];
    }

    return _assistantJobs
        .where(
          (job) => _normalizeText(job.categoryName) == _normalizeText(categoryName),
        )
        .toList();
  }

  JobResponseDto? _firstJobForCategory(
    List<JobResponseDto> jobs,
    String? categoryName,
  ) {
    if (categoryName == null) {
      return jobs.isEmpty ? null : jobs.first;
    }

    for (final job in jobs) {
      if (_normalizeText(job.categoryName) == _normalizeText(categoryName)) {
        return job;
      }
    }

    return jobs.isEmpty ? null : jobs.first;
  }

  bool _matchesCategoryAssignment(
    String categoryName,
    UserServiceAssignmentResponseDto assignment,
  ) {
    return _normalizeText(assignment.serviceName) == _normalizeText(categoryName);
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDate ?? now.add(const Duration(days: 1));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate == null || !mounted) return;
    setState(() {
      _selectedDate = pickedDate;
    });
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
    );

    if (pickedTime == null || !mounted) return;
    setState(() {
      _selectedTime = pickedTime;
    });
  }

  Future<void> _addAddress() async {
    final currentUserId = _currentUser?.id;
    if (currentUserId == null || _isOpeningAddress) {
      return;
    }

    setState(() {
      _isOpeningAddress = true;
    });

    final createdAddress = await Navigator.of(context).push<AddressResponseDto>(
      MaterialPageRoute<AddressResponseDto>(
        builder: (_) => AddressFormScreen(userId: currentUserId),
      ),
    );

    if (!mounted) return;

    if (createdAddress != null) {
      setState(() {
        _addresses = [createdAddress, ..._addresses];
        _selectedAddress = createdAddress;
      });
    }

    setState(() {
      _isOpeningAddress = false;
    });
  }

  void _continue() {
    final currentUser = _currentUser;
    final category = _selectedCategory;
    final job = _selectedJob;
    final address = _selectedAddress;
    final date = _selectedDate;
    final time = _selectedTime;

    if (currentUser == null ||
        currentUser.id == null ||
        category == null ||
        job == null ||
        address == null ||
        date == null ||
        time == null) {
      _showMessage('Completa servicio, direccion, fecha y hora.');
      return;
    }

    final startTime = _formatTimeOfDay(time);
    final endTime = _calculateEndTime(time, job.durationMinutes);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServicePaymentSummaryScreen(
          selection: ServiceBookingSelection(
            customer: currentUser,
            assistant: widget.assistant,
            category: category,
            job: job,
            address: address,
            serviceDate: date,
            startTime: startTime,
            endTime: endTime,
            note: _noteController.text.trim(),
          ),
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  String _calculateEndTime(TimeOfDay time, int durationMinutes) {
    final totalMinutes = time.hour * 60 + time.minute + durationMinutes;
    final endHour = (totalMinutes ~/ 60) % 24;
    final endMinute = totalMinutes % 60;
    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}:00';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _buildBody(scale),
      ),
    );
  }

  Widget _buildBody(double scale) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.turquoise),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        padding: EdgeInsets.all(24 * scale),
        children: [
          SizedBox(height: 100 * scale),
          _InfoCard(
            title: 'No se pudo cargar esta pantalla',
            message: _errorMessage!,
            actionLabel: 'Reintentar',
            onPressed: _loadData,
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        22 * scale,
        12 * scale,
        22 * scale,
        28 * scale,
      ),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: const Color(0xFF7BA2C7),
                size: 22 * scale,
              ),
            ),
            Expanded(
              child: Text(
                'Confirmar servicio',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 27 * scale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF7BA2C7),
                ),
              ),
            ),
            SizedBox(width: 48 * scale),
          ],
        ),
        SizedBox(height: 18 * scale),
        _AssistantHeader(
          assistant: widget.assistant,
          scale: scale,
        ),
        SizedBox(height: 22 * scale),
        Text(
          'Categoria',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18 * scale,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF434343),
          ),
        ),
        SizedBox(height: 12 * scale),
        if (_categories.isEmpty)
          const _InfoCard(
            title: 'Este asistente no tiene servicios disponibles',
            message: 'No hay categorias asignadas ahora mismo.',
          )
        else
          _CategoryCarousel(
            categories: _categories,
            selectedCategory: _selectedCategory,
            scale: scale,
            onSelected: (category) {
              setState(() {
                _selectedCategory = category;
                _selectedJob = _firstJobForCategory(
                  _assistantJobs,
                  category.name,
                );
              });
            },
          ),
        SizedBox(height: 18 * scale),
        Text(
          'Servicios',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18 * scale,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF434343),
          ),
        ),
        SizedBox(height: 12 * scale),
        if (_visibleJobs.isEmpty)
          const _InfoCard(
            title: 'No hay servicios en esta categoria',
            message: 'Prueba con otra categoria para continuar.',
          )
        else
          SizedBox(
            height: 108 * scale,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _visibleJobs.length,
              separatorBuilder: (_, __) => SizedBox(width: 12 * scale),
              itemBuilder: (context, index) {
                final job = _visibleJobs[index];
                final isSelected = _selectedJob?.id == job.id;
                return _JobCard(
                  job: job,
                  isSelected: isSelected,
                  scale: scale,
                  onTap: () {
                    setState(() {
                      _selectedJob = job;
                    });
                  },
                );
              },
            ),
          ),
        SizedBox(height: 24 * scale),
        _SectionTitle(title: 'Direccion', scale: scale),
        SizedBox(height: 10 * scale),
        if (_addresses.isEmpty)
          _InfoCard(
            title: 'No tienes direccion registrada',
            message: 'Anade una direccion para que podamos cerrar la reserva.',
            actionLabel: _isOpeningAddress ? 'Abriendo...' : 'Anadir direccion',
            onPressed: _isOpeningAddress ? null : _addAddress,
          )
        else
          Column(
            children: [
              ..._addresses.map(
                (address) => Padding(
                  padding: EdgeInsets.only(bottom: 10 * scale),
                  child: _AddressCard(
                    address: address,
                    isSelected: _selectedAddress?.id == address.id,
                    scale: scale,
                    onTap: () {
                      setState(() {
                        _selectedAddress = address;
                      });
                    },
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isOpeningAddress ? null : _addAddress,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Nueva direccion'),
                ),
              ),
            ],
          ),
        SizedBox(height: 12 * scale),
        _SectionTitle(title: 'Horario', scale: scale),
        SizedBox(height: 10 * scale),
        Row(
          children: [
            Expanded(
              child: _PickerButton(
                icon: Icons.calendar_today_outlined,
                label: _selectedDate == null
                    ? 'Dia del servicio'
                    : _dateLabel(_selectedDate!),
                scale: scale,
                onTap: _pickDate,
              ),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: _PickerButton(
                icon: Icons.access_time_outlined,
                label: _selectedTime == null
                    ? 'Hora de inicio'
                    : _timeLabel(_selectedTime!),
                scale: scale,
                onTap: _pickTime,
              ),
            ),
          ],
        ),
        if (_selectedTime != null && _selectedJob != null) ...[
          SizedBox(height: 12 * scale),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16 * scale,
              vertical: 14 * scale,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(color: const Color(0xFFB7D4EA)),
              color: const Color(0xFFF8FBFD),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timelapse_outlined,
                  color: AppColors.navyBlue,
                  size: 18 * scale,
                ),
                SizedBox(width: 10 * scale),
                Expanded(
                  child: Text(
                    'Termina sobre ${_calculateEndTime(_selectedTime!, _selectedJob!.durationMinutes).substring(0, 5)} - ${_selectedJob!.durationMinutes} min',
                    style: TextStyle(
                      fontSize: 14 * scale,
                      color: const Color(0xFF444444),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 18 * scale),
        _SectionTitle(title: 'Especificaciones', scale: scale),
        SizedBox(height: 10 * scale),
        TextField(
          controller: _noteController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Especificaciones ...',
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.all(16 * scale),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18 * scale),
              borderSide: const BorderSide(color: Color(0xFF7FC5E5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18 * scale),
              borderSide: const BorderSide(color: AppColors.turquoise),
            ),
          ),
        ),
        SizedBox(height: 18 * scale),
        if (_selectedJob != null)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16 * scale,
              vertical: 14 * scale,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16 * scale),
              color: const Color(0xFFF8FBFD),
              border: Border.all(color: const Color(0xFFB7D4EA)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedJob!.name,
                    style: TextStyle(
                      fontSize: 16 * scale,
                      color: const Color(0xFF2A2A2A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _selectedJob!.price == null
                      ? '--'
                      : '${_selectedJob!.price!.toStringAsFixed(2)} EUR',
                  style: TextStyle(
                    fontSize: 18 * scale,
                    color: AppColors.navyBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 20 * scale),
        SizedBox(
          height: 52 * scale,
          child: ElevatedButton(
            onPressed: _continue,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8DB0D3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18 * scale),
              ),
            ),
            child: Text(
              'Continuar',
              style: TextStyle(
                fontSize: 18 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(height: 12 * scale),
        SizedBox(
          height: 52 * scale,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8DB0D3),
              side: const BorderSide(color: Color(0xFF8DB0D3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18 * scale),
              ),
            ),
            child: Text(
              'Volver',
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _timeLabel(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _AssistantHeader extends StatelessWidget {
  const _AssistantHeader({
    required this.assistant,
    required this.scale,
  });

  final UserResponseDto assistant;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 14 * scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: const Color(0xFFD7E5F2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_circle_outlined,
            color: AppColors.navyBlue,
            size: 42 * scale,
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assistant.fullName.trim().isEmpty
                      ? 'Asistente'
                      : assistant.fullName.trim(),
                  style: TextStyle(
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B3D5D),
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  assistant.phoneNumber.trim().isEmpty
                      ? 'Telefono pendiente'
                      : assistant.phoneNumber.trim(),
                  style: TextStyle(
                    fontSize: 13 * scale,
                    color: const Color(0xFF4D667A),
                  ),
                ),
              ],
            ),
          ),
          if (assistant.averageRating > 0)
            Text(
              assistant.averageRating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 20 * scale,
                fontWeight: FontWeight.w800,
                color: AppColors.navyBlue,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryCarousel extends StatelessWidget {
  const _CategoryCarousel({
    required this.categories,
    required this.selectedCategory,
    required this.scale,
    required this.onSelected,
  });

  final List<CategoryResponseDto> categories;
  final CategoryResponseDto? selectedCategory;
  final double scale;
  final ValueChanged<CategoryResponseDto> onSelected;

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
          final isSelected = selectedCategory?.id == category.id;

          return GestureDetector(
            onTap: () => onSelected(category),
            child: SizedBox(
              width: 76 * scale,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 58 * scale,
                    height: 58 * scale,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFD9EBFB)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(10 * scale),
                    child: _SafeCategoryIcon(
                      assetPath: _safeCategoryAssetPathFromName(category.name),
                      scale: scale,
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

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.isSelected,
    required this.scale,
    required this.onTap,
  });

  final JobResponseDto job;
  final bool isSelected;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 150 * scale,
        padding: EdgeInsets.all(14 * scale),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8DB0D3) : const Color(0xFFF8FBFD),
          borderRadius: BorderRadius.circular(18 * scale),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8DB0D3)
                : const Color(0xFFD7E5F2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15 * scale,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF2E3F51),
              ),
            ),
            SizedBox(height: 10 * scale),
            Text(
              job.price == null ? '--' : '${job.price!.toStringAsFixed(2)} EUR',
              style: TextStyle(
                fontSize: 20 * scale,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.navyBlue,
              ),
            ),
            SizedBox(height: 4 * scale),
            Text(
              '${job.durationMinutes} min',
              style: TextStyle(
                fontSize: 12 * scale,
                color:
                    isSelected ? const Color(0xFFEFF7FF) : const Color(0xFF56708A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.isSelected,
    required this.scale,
    required this.onTap,
  });

  final AddressResponseDto address;
  final bool isSelected;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18 * scale),
      child: Container(
        padding: EdgeInsets.all(14 * scale),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18 * scale),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8DB0D3)
                : const Color(0xFFD7E5F2),
            width: isSelected ? 1.5 : 1,
          ),
          color: isSelected ? const Color(0xFFF1F7FC) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off_outlined,
              color: const Color(0xFF8DB0D3),
              size: 20 * scale,
            ),
            SizedBox(width: 10 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.street,
                    style: TextStyle(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E3F51),
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    '${address.city}, ${address.zipCode}, ${address.country}',
                    style: TextStyle(
                      fontSize: 12 * scale,
                      color: const Color(0xFF56708A),
                    ),
                  ),
                  if ((address.description ?? '').trim().isNotEmpty) ...[
                    SizedBox(height: 4 * scale),
                    Text(
                      address.description!.trim(),
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: const Color(0xFF56708A),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (address.isPrimary)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale,
                  vertical: 4 * scale,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9EBFB),
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
                child: Text(
                  'Principal',
                  style: TextStyle(
                    fontSize: 10 * scale,
                    color: AppColors.navyBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.scale,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16 * scale),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14 * scale,
          vertical: 15 * scale,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(color: const Color(0xFFB7D4EA)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18 * scale, color: AppColors.navyBlue),
            SizedBox(width: 10 * scale),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13 * scale,
                  color: const Color(0xFF5E6F7E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.scale,
  });

  final String title;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18 * scale,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF434343),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
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
  });

  final String assetPath;
  final double scale;

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
        size: 28 * widget.scale,
      );
    }

    return SvgPicture.asset(
      widget.assetPath,
      fit: BoxFit.contain,
    );
  }
}

String _safeCategoryAssetPathFromName(String categoryName) {
  final normalizedCategoryName = categoryName
      .trim()
      .toLowerCase()
      .replaceAll('ñ', 'n');

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
    case 'tramites':
      return 'assets/images/categories/tecnologia.svg';
    default:
      return 'assets/images/categories/limpieza.svg';
  }
}
