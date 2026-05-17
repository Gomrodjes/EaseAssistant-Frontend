import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/app_colors.dart';
import '../../../../config/measures.dart';
import '../../../../models/models.dart';
import '../../../../services/category_service.dart';
import '../../../../services/user_service_assignment_service.dart';
import 'application_flow_widgets.dart';
import 'waiting_application_responde_screen.dart';

class AssistantProfileCategoriesScreen extends StatefulWidget {
  const AssistantProfileCategoriesScreen({
    super.key,
    required this.userId,
  });

  final int userId;

  @override
  State<AssistantProfileCategoriesScreen> createState() =>
      _AssistantProfileCategoriesScreenState();
}

class _AssistantProfileCategoriesScreenState
    extends State<AssistantProfileCategoriesScreen> {
  final CategoryService _categoryService = CategoryService();
  final UserServiceAssignmentService _assignmentService =
      UserServiceAssignmentService();

  final Set<int> _selectedCategoryIds = <int>{};

  List<CategoryResponseDto> _categories = const <CategoryResponseDto>[];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _categoryService.dispose();
    _assignmentService.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _categoryService.getAllCategories();
      final activeCategories = (response.data ?? <CategoryResponseDto>[])
          .where((category) => category.active && category.id != null)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (!mounted) return;

      setState(() {
        _categories = activeCategories;
        _isLoading = false;
      });
    } on CategoryServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron cargar las categorias disponibles.'),
        ),
      );
    }
  }

  void _toggleCategory(int categoryId) {
    if (_isSubmitting) return;

    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
    });
  }

  bool get _canContinue =>
      !_isLoading && !_isSubmitting && _selectedCategoryIds.isNotEmpty;

  Future<void> _saveCategories() async {
    if (!_canContinue) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      for (final categoryId in _selectedCategoryIds) {
        await _assignmentService.activateAssignment(
          userId: widget.userId,
          categoryId: categoryId,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const WaitingApplicationRespondeScreen(),
        ),
        (route) => false,
      );
    } on UserServiceAssignmentServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron guardar las categorias seleccionadas.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ApplicationFlowScaffold(
      titleTop: 'Configuracion',
      titleBottom: 'Perfil Personal',
      description:
          'Aqui podras configurar tu perfil como trabajador y marcar los servicios que quieres ofrecer.',
      buttonLabel: 'Enviar para revision',
      onContinue: _saveCategories,
      isContinueEnabled: _canContinue,
      isSubmitting: _isSubmitting,
      children: [
        const ApplicationFlowInfoCard(
          message:
              'Selecciona al menos una categoria para completar la configuracion de tu perfil.',
        ),
        _CategorySelectionSection(
          categories: _categories,
          selectedCategoryIds: _selectedCategoryIds,
          isLoading: _isLoading,
          onToggle: _toggleCategory,
        ),
      ],
    );
  }
}

class _CategorySelectionSection extends StatelessWidget {
  const _CategorySelectionSection({
    required this.categories,
    required this.selectedCategoryIds,
    required this.isLoading,
    required this.onToggle,
  });

  final List<CategoryResponseDto> categories;
  final Set<int> selectedCategoryIds;
  final bool isLoading;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    if (isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 24 * scale),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.turquoise),
        ),
      );
    }

    if (categories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(18 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FBFC),
          borderRadius: BorderRadius.circular(18 * scale),
          border: Border.all(color: AppColors.turquoise.withOpacity(0.25)),
        ),
        child: Text(
          'Ahora mismo no hay categorias activas disponibles.',
          style: GoogleFonts.poppins(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w600,
            color: AppColors.navyBlue,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 14 * scale, left: 4 * scale),
          child: Text(
            'Servicios que ofreces',
            style: GoogleFonts.poppins(
              fontSize: 22 * scale,
              fontWeight: FontWeight.w800,
              color: AppColors.purple,
            ),
          ),
        ),
        Wrap(
          spacing: 12 * scale,
          runSpacing: 12 * scale,
          children: categories.map((category) {
            final categoryId = category.id!;
            final selected = selectedCategoryIds.contains(categoryId);

            return _CategoryChipCard(
              category: category,
              selected: selected,
              onTap: () => onToggle(categoryId),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CategoryChipCard extends StatelessWidget {
  const _CategoryChipCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryResponseDto category;
  final bool selected;
  final VoidCallback onTap;

  static const Map<String, String> _categoryIcons = {
    'limpieza': 'assets/images/categories/limpieza.svg',
    'cuidado personal': 'assets/images/categories/cuidado_personal.svg',
    'tecnologia': 'assets/images/categories/tecnologia.svg',
    'transporte': 'assets/images/categories/transporte.svg',
    'cocina': 'assets/images/categories/cocina.svg',
    'acompanamiento': 'assets/images/categories/compania.svg',
  };

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);
    final normalizedName = _normalizeCategoryName(category.name);
    final iconPath = _categoryIcons[normalizedName];

    return SizedBox(
      width: 160 * scale,
      child: Material(
        color: selected ? AppColors.turquoise : Colors.white,
        borderRadius: BorderRadius.circular(20 * scale),
        elevation: selected ? 5 : 2,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20 * scale),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: 14 * scale,
              vertical: 16 * scale,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20 * scale),
              border: Border.all(
                color: selected
                    ? AppColors.turquoise
                    : AppColors.navyBlue.withOpacity(0.12),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: iconPath == null
                          ? Container(
                              width: 42 * scale,
                              height: 42 * scale,
                              decoration: BoxDecoration(
                                color: (selected
                                        ? Colors.white
                                        : AppColors.turquoise)
                                    .withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14 * scale),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.work_outline_rounded,
                                color: selected
                                    ? Colors.white
                                    : AppColors.navyBlue,
                                size: 22 * scale,
                              ),
                            )
                          : Container(
                              width: 42 * scale,
                              height: 42 * scale,
                              padding: EdgeInsets.all(8 * scale),
                              decoration: BoxDecoration(
                                color: (selected
                                        ? Colors.white
                                        : AppColors.turquoise)
                                    .withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14 * scale),
                              ),
                              child: SvgPicture.asset(
                                iconPath,
                                colorFilter: ColorFilter.mode(
                                  selected
                                      ? Colors.white
                                      : AppColors.navyBlue,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 28 * scale,
                      height: 28 * scale,
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? Colors.white
                              : AppColors.navyBlue.withOpacity(0.35),
                          width: 1.4,
                        ),
                      ),
                      child: selected
                          ? Icon(
                              Icons.check_rounded,
                              size: 18 * scale,
                              color: AppColors.turquoise,
                            )
                          : null,
                    ),
                  ],
                ),
                SizedBox(height: 16 * scale),
                Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: selected ? Colors.white : AppColors.navyBlue,
                  ),
                ),
                if ((category.description ?? '').trim().isNotEmpty) ...[
                  SizedBox(height: 8 * scale),
                  Text(
                    category.description!.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5 * scale,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                      color: selected
                          ? Colors.white.withOpacity(0.92)
                          : AppColors.navyBlue.withOpacity(0.78),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _normalizeCategoryName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('\u00E1', 'a')
        .replaceAll('\u00E9', 'e')
        .replaceAll('\u00ED', 'i')
        .replaceAll('\u00F3', 'o')
        .replaceAll('\u00FA', 'u')
        .replaceAll('\u00F1', 'n');
  }
}
