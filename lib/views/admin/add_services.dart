import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/measures.dart';
import '../../models/models.dart';
import '../../services/category_service.dart';
import '../../services/job_service.dart';

class AddServices extends StatefulWidget {
  const AddServices({super.key});

  @override
  State<AddServices> createState() => _AddServicesState();
}

class _AddServicesState extends State<AddServices> {
  final CategoryService _categoryService = CategoryService();
  final JobService _jobService = JobService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController(
    text: '25.00',
  );
  final TextEditingController _durationController = TextEditingController(
    text: '60',
  );

  List<CategoryResponseDto> _categories = <CategoryResponseDto>[];
  CategoryResponseDto? _selectedCategory;
  bool _isLoadingCategories = true;
  bool _isSubmitting = false;
  String? _categoryErrorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Limpieza profunda';
    _descriptionController.text =
        'Servicio orientado a espacios que requieren una puesta a punto completa y rapida.';
    _loadCategories();
  }

  @override
  void dispose() {
    _categoryService.dispose();
    _jobService.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryErrorMessage = null;
    });

    try {
      final response = await _categoryService.getAllCategories();
      final categories = (response.data ?? <CategoryResponseDto>[])
          .where(
            (category) =>
                category.active &&
                category.id != null &&
                category.name.trim().isNotEmpty,
          )
          .toList()
        ..sort(
          (first, second) =>
              first.name.toLowerCase().compareTo(second.name.toLowerCase()),
        );

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _selectedCategory = categories.isEmpty ? null : categories.first;
        _isLoadingCategories = false;
      });
    } on CategoryServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _categoryErrorMessage = e.message;
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categoryErrorMessage = 'No se pudieron cargar las categorias.';
        _isLoadingCategories = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _nameController.text = '';
      _descriptionController.text = '';
      _priceController.text = '';
      _durationController.text = '';
      _selectedCategory = _categories.isEmpty ? null : _categories.first;
    });
  }

  String? _validateForm() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final priceText = _priceController.text.trim().replaceAll(',', '.');
    final durationText = _durationController.text.trim();
    final parsedPrice = double.tryParse(priceText);
    final parsedDuration = int.tryParse(durationText);

    if (name.isEmpty) {
      return 'Introduce el nombre del servicio.';
    }

    if (description.isEmpty) {
      return 'Introduce una descripcion del servicio.';
    }

    if (description.length > 500) {
      return 'La descripcion no puede superar los 500 caracteres.';
    }

    if (parsedPrice == null || parsedPrice <= 0) {
      return 'Introduce un precio valido mayor que 0.';
    }

    if (parsedDuration == null || parsedDuration < 1) {
      return 'La duracion debe ser de al menos 1 minuto.';
    }

    if (_selectedCategory?.id == null) {
      return 'Selecciona una categoria.';
    }

    return null;
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();

    final validationMessage = _validateForm();
    if (validationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFF2B1F),
          content: Text(validationMessage),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final request = JobSaveDto(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text.trim().replaceAll(',', '.')),
      durationMinutes: int.parse(_durationController.text.trim()),
      categoryId: _selectedCategory!.id!,
    );

    try {
      final response = await _jobService.createJob(request);
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.navyBlue,
          content: Text(
            response.message.isNotEmpty
                ? response.message
                : 'Servicio creado correctamente.',
          ),
        ),
      );

      _resetForm();
    } on JobServiceException catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFF2B1F),
          content: Text(e.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFFF2B1F),
          content: Text('No se pudo crear el servicio.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);
    final serviceName = _nameController.text.trim().isEmpty
        ? 'Nombre del servicio'
        : _nameController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? 'Aqui aparecera la descripcion resumida del servicio.'
        : _descriptionController.text.trim();
    final price = _priceController.text.trim().isEmpty
        ? '--'
        : _priceController.text.trim();
    final duration = _durationController.text.trim().isEmpty
        ? '--'
        : _durationController.text.trim();
    final selectedCategory = _selectedCategory?.name ?? 'Sin categoria';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Anadir servicios'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navyBlue,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.turquoise,
        onRefresh: _loadCategories,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            20 * scale,
            14 * scale,
            20 * scale,
            28 * scale,
          ),
          children: [
            _IntroCard(scale: scale),
            SizedBox(height: 18 * scale),
            _SectionCard(
              scale: scale,
              title: 'Datos principales',
              child: Column(
                children: [
                  _StyledTextField(
                    controller: _nameController,
                    label: 'Nombre del servicio',
                    hintText: 'Ej. Limpieza profunda',
                    scale: scale,
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 14 * scale),
                  _StyledTextField(
                    controller: _descriptionController,
                    label: 'Descripcion',
                    hintText: 'Explica que incluye el servicio',
                    scale: scale,
                    minLines: 4,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14 * scale),
            _SectionCard(
              scale: scale,
              title: 'Configuracion',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StyledTextField(
                          controller: _priceController,
                          label: 'Precio base',
                          hintText: '25.00',
                          scale: scale,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      SizedBox(width: 12 * scale),
                      Expanded(
                        child: _StyledTextField(
                          controller: _durationController,
                          label: 'Duracion',
                          hintText: '60',
                          scale: scale,
                          keyboardType: TextInputType.number,
                          suffixText: 'min',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16 * scale),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Categoria',
                      style: TextStyle(
                        color: AppColors.navyBlue,
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: 10 * scale),
                  if (_isLoadingCategories)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12 * scale),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.turquoise,
                        ),
                      ),
                    )
                  else if (_categoryErrorMessage != null)
                    _InlineInfoCard(
                      scale: scale,
                      message: _categoryErrorMessage!,
                      actionLabel: 'Reintentar',
                      onAction: _loadCategories,
                    )
                  else if (_categories.isEmpty)
                    _InlineInfoCard(
                      scale: scale,
                      message: 'No hay categorias activas disponibles.',
                      actionLabel: 'Actualizar',
                      onAction: _loadCategories,
                    )
                  else
                    Wrap(
                      spacing: 8 * scale,
                      runSpacing: 8 * scale,
                      children: _categories.map((category) {
                        final isSelected = category.id == _selectedCategory?.id;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: EdgeInsets.symmetric(
                              horizontal: 12 * scale,
                              vertical: 8 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.navyBlue
                                  : const Color(0xFFF7FBFD),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.navyBlue
                                    : AppColors.navyBlue.withOpacity(0.18),
                              ),
                            ),
                            child: Text(
                              category.name,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.navyBlue,
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            SizedBox(height: 14 * scale),
            _SectionCard(
              scale: scale,
              title: 'Vista previa',
              child: _ServicePreviewCard(
                scale: scale,
                name: serviceName,
                description: description,
                price: price,
                duration: duration,
                category: selectedCategory,
              ),
            ),
            SizedBox(height: 18 * scale),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _resetForm,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navyBlue,
                      side: BorderSide(
                        color: AppColors.navyBlue.withOpacity(0.5),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14 * scale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18 * scale),
                      ),
                    ),
                    child: Text(
                      'Limpiar',
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 14 * scale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18 * scale),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 18 * scale,
                            height: 18 * scale,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF9AE6EB),
                              ),
                            ),
                          )
                        : Text(
                            'Guardar servicio',
                            style: TextStyle(
                              color: const Color(0xFF9AE6EB),
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineInfoCard extends StatelessWidget {
  const _InlineInfoCard({
    required this.scale,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final double scale;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFD),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: AppColors.navyBlue.withOpacity(0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              color: AppColors.navyBlue,
              fontSize: 12 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8 * scale),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.navyBlue,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.scale,
  });

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFD),
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(
          color: AppColors.turquoise.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Crea nuevos servicios',
            style: TextStyle(
              color: AppColors.navyBlue,
              fontSize: 19 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            'Define la informacion principal, selecciona una categoria real del sistema y revisa la tarjeta final antes de guardar.',
            style: TextStyle(
              color: AppColors.navyBlue.withOpacity(0.68),
              fontSize: 13 * scale,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.scale,
    required this.title,
    required this.child,
  });

  final double scale;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(
          color: AppColors.navyBlue.withOpacity(0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.navyBlue,
              fontSize: 16 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 14 * scale),
          child,
        ],
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.scale,
    required this.onChanged,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.suffixText,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final double scale;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final String? suffixText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.navyBlue,
            fontSize: 13 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8 * scale),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          cursorColor: AppColors.navyBlue,
          style: TextStyle(
            color: AppColors.navyBlue,
            fontSize: 13 * scale,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.navyBlue.withOpacity(0.36),
              fontSize: 12 * scale,
            ),
            suffixText: suffixText,
            suffixStyle: TextStyle(
              color: AppColors.navyBlue.withOpacity(0.6),
              fontSize: 12 * scale,
              fontWeight: FontWeight.w700,
            ),
            filled: true,
            fillColor: const Color(0xFFFDFEFE),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14 * scale,
              vertical: 12 * scale,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16 * scale),
              borderSide: BorderSide(
                color: AppColors.navyBlue.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16 * scale),
              borderSide: const BorderSide(
                color: AppColors.navyBlue,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ServicePreviewCard extends StatelessWidget {
  const _ServicePreviewCard({
    required this.scale,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    required this.category,
  });

  final double scale;
  final String name;
  final String description;
  final String price;
  final String duration;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFD),
        borderRadius: BorderRadius.circular(22 * scale),
        border: Border.all(
          color: AppColors.navyBlue.withOpacity(0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              color: AppColors.navyBlue,
              fontSize: 17 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            description,
            style: TextStyle(
              color: AppColors.navyBlue.withOpacity(0.7),
              fontSize: 12 * scale,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          SizedBox(height: 14 * scale),
          Wrap(
            spacing: 8 * scale,
            runSpacing: 8 * scale,
            children: [
              _PreviewChip(
                scale: scale,
                label: '$price EUR',
                icon: Icons.payments_outlined,
              ),
              _PreviewChip(
                scale: scale,
                label: '$duration min',
                icon: Icons.schedule_outlined,
              ),
              _PreviewChip(
                scale: scale,
                label: category,
                icon: Icons.category_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.scale,
    required this.label,
    required this.icon,
  });

  final double scale;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 7 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.turquoise.withOpacity(0.55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.navyBlue,
            size: 14 * scale,
          ),
          SizedBox(width: 6 * scale),
          Text(
            label,
            style: TextStyle(
              color: AppColors.navyBlue,
              fontSize: 11 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
