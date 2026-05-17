import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/app_colors.dart';
import '../../../config/measures.dart';
import '../../../models/category_models.dart';
import '../../../models/core/app_enums.dart';
import '../../../models/user_models.dart';
import '../../../models/user_service_assignment_models.dart';
import '../../../services/category_service.dart';
import '../../../services/user_service.dart';
import '../../../services/user_service_assignment_service.dart';
import 'confirm_service.dart';

class BuyServiceScreen extends StatefulWidget {
  const BuyServiceScreen({super.key});

  @override
  State<BuyServiceScreen> createState() => _BuyServiceScreenState();
}

class _BuyServiceScreenState extends State<BuyServiceScreen> {
  final CategoryService _categoryService = CategoryService();
  final UserService _userService = UserService();
  final UserServiceAssignmentService _assignmentService =
      UserServiceAssignmentService();

  bool _isLoading = true;
  String? _errorMessage;

  List<CategoryResponseDto> _categories = const <CategoryResponseDto>[];
  List<UserResponseDto> _assistants = const <UserResponseDto>[];
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
    _categoryService.dispose();
    _userService.dispose();
    _assignmentService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categoriesResponse = await _categoryService.getAllCategories();
      final usersResponse = await _userService.getAllUsers();

      final categories = (categoriesResponse.data ?? <CategoryResponseDto>[])
          .where((category) => category.active && category.name.trim().isNotEmpty)
          .toList()
        ..sort(
          (first, second) => first.name.toLowerCase().compareTo(
                second.name.toLowerCase(),
              ),
        );

      final assistants = (usersResponse.data ?? <UserResponseDto>[])
          .where(
            (user) =>
                user.role == UserRole.assistant && user.isActive,
          )
          .where((user) => user.documentationVerified)
          .toList()
        ..sort(
          (first, second) => first.fullName.toLowerCase().compareTo(
                second.fullName.toLowerCase(),
              ),
        );

      final assignmentsBuffer = <UserServiceAssignmentResponseDto>[];
      for (final assistant in assistants) {
        final assistantId = assistant.id;
        if (assistantId == null) {
          continue;
        }
        final response = await _assignmentService.getAssignmentsByUser(
          assistantId,
        );
        assignmentsBuffer.addAll(
          (response.data ?? <UserServiceAssignmentResponseDto>[])
              .where((assignment) => assignment.active),
        );
      }

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _assistants = assistants;
        _assignments = _deduplicateAssignments(assignmentsBuffer);
        _isLoading = false;
      });
    } on CategoryServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } on UserServiceException catch (e) {
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
        _errorMessage = 'No se pudo cargar la lista de ayudantes.';
        _isLoading = false;
      });
    }
  }

  List<UserServiceAssignmentResponseDto> _deduplicateAssignments(
    List<UserServiceAssignmentResponseDto> assignments,
  ) {
    final seenKeys = <String>{};
    final uniqueAssignments = <UserServiceAssignmentResponseDto>[];

    for (final assignment in assignments) {
      final key = '${assignment.userId}-${assignment.serviceId}';
      if (seenKeys.add(key)) {
        uniqueAssignments.add(assignment);
      }
    }

    return uniqueAssignments;
  }

  List<UserResponseDto> get _visibleAssistants {
    if (_selectedCategoryName == null) {
      return _assistants;
    }

    final selectedCategory = _findCategoryByName(_selectedCategoryName!);

    if (selectedCategory == null) {
      return _assistants;
    }

    final allowedUserIds = _assignments
        .where(
          (assignment) =>
              assignment.active &&
              _matchesCategoryAssignment(selectedCategory, assignment),
        )
        .map((assignment) => assignment.userId)
        .toSet();

    return _assistants
        .where((assistant) => allowedUserIds.contains(assistant.id))
        .toList();
  }

  CategoryResponseDto? _findCategoryByName(String categoryName) {
    for (final category in _categories) {
      if (_normalizeText(category.name) == _normalizeText(categoryName)) {
        return category;
      }
    }

    return null;
  }

  bool _matchesCategoryAssignment(
    CategoryResponseDto category,
    UserServiceAssignmentResponseDto assignment,
  ) {
    final categoryId = category.id;
    if (categoryId != null && assignment.serviceId == categoryId) {
      return true;
    }

    return _normalizeText(assignment.serviceName) == _normalizeText(category.name);
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
        .replaceAll('Ã¡', 'a')
        .replaceAll('Ã©', 'e')
        .replaceAll('Ã­', 'i')
        .replaceAll('Ã³', 'o')
        .replaceAll('Ãº', 'u')
        .replaceAll('Ã±', 'n')
        .replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.turquoise,
          onRefresh: _loadData,
          child: _buildBody(context, scale),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, double scale) {
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

    final visibleAssistants = _visibleAssistants;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        18 * scale,
        16 * scale,
        18 * scale,
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
                size: 24 * scale,
              ),
            ),
            Expanded(
              child: Text(
                'Buscar Ayuda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28 * scale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF7BA2C7),
                ),
              ),
            ),
            SizedBox(width: 48 * scale),
          ],
        ),
        SizedBox(height: 16 * scale),
        if (_categories.isNotEmpty)
          _CategoryFilterList(
            categories: _categories,
            selectedCategoryName: _selectedCategoryName,
            scale: scale,
            onSelected: (categoryName) {
              setState(() {
                _selectedCategoryName =
                    _selectedCategoryName == categoryName ? null : categoryName;
              });
            },
          ),
        SizedBox(height: 26 * scale),
        Text(
          'Ayudantes',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19 * scale,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF434343),
          ),
        ),
        SizedBox(height: 18 * scale),
        if (visibleAssistants.isEmpty)
          _InfoMessageCard(
            title: 'No hay ayudantes disponibles',
            message: _selectedCategoryName == null
                ? 'Todavia no hay asistentes visibles para mostrar.'
                : 'No hay asistentes que ofrezcan esta categoria ahora mismo.',
          )
        else
          ...visibleAssistants.map(
            (assistant) => Padding(
              padding: EdgeInsets.only(bottom: 18 * scale),
              child: _AssistantCard(
                assistant: assistant,
                scale: scale,
                hasSuperStar: assistant.averageRating >= 4.8,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ConfirmServiceScreen(
                        assistant: assistant,
                        initialCategoryName: _selectedCategoryName,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _AssistantCard extends StatelessWidget {
  const _AssistantCard({
    required this.assistant,
    required this.scale,
    required this.hasSuperStar,
    required this.onTap,
  });

  final UserResponseDto assistant;
  final double scale;
  final bool hasSuperStar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratingValue = assistant.averageRating;
    final flooredRating = ratingValue.floor();
    final fullStars = flooredRating < 0
        ? 0
        : flooredRating > 5
            ? 5
            : flooredRating;
    final hasAnyRating = assistant.numberOfReviews > 0 || ratingValue > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24 * scale),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF8DB0D3),
            borderRadius: BorderRadius.circular(24 * scale),
            border: Border.all(
              color:
                  hasSuperStar ? Colors.transparent : const Color(0xFF8DB0D3),
              width: hasSuperStar ? 0 : 2.5,
            ),
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
            vertical: 14 * scale,
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                color: AppColors.navyBlue,
                size: 38 * scale,
              ),
              SizedBox(width: 14 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assistant.fullName.trim().isEmpty
                          ? 'Nombre de usuario'
                          : assistant.fullName.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1B3D5D),
                      ),
                    ),
                    SizedBox(height: 6 * scale),
                    Row(
                      children: [
                        if (hasAnyRating)
                          ...List<Widget>.generate(
                            fullStars,
                            (index) => Padding(
                              padding: EdgeInsets.only(right: 3 * scale),
                              child: Icon(
                                Icons.star_outline,
                                color: AppColors.navyBlue,
                                size: 15 * scale,
                              ),
                            ),
                          )
                        else
                          Text(
                            'Sin valoraciones',
                            style: TextStyle(
                              fontSize: 12 * scale,
                              color: const Color(0xFF1B3D5D),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasSuperStar)
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.navyBlue,
                  size: 34 * scale,
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
              width: 70 * scale,
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
      .replaceAll('Ã±', 'n')
      .replaceAll('ÃƒÂ±', 'n');

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
