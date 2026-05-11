import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/measures.dart';
import '../../models/models.dart';
import '../../services/category_service.dart';

class AddCategories extends StatefulWidget {
  const AddCategories({super.key});

  @override
  State<AddCategories> createState() => _AddCategoriesState();
}

class _AddCategoriesState extends State<AddCategories> {
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isActive = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Mantenimiento del hogar';
    _descriptionController.text =
        'Categoria pensada para agrupar servicios frecuentes de soporte y mantenimiento domestico.';
  }

  @override
  void dispose() {
    _categoryService.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _nameController.text = '';
      _descriptionController.text = '';
      _isActive = true;
    });
  }

  String? _validateForm() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      return 'Introduce el nombre de la categoria.';
    }

    if (description.length > 500) {
      return 'La descripcion no puede superar los 500 caracteres.';
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

    final request = CategorySaveDto(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      active: _isActive,
    );

    try {
      final response = await _categoryService.createCategory(request);
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
                : 'Categoria creada correctamente.',
          ),
        ),
      );

      _resetForm();
    } on CategoryServiceException catch (e) {
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
          content: Text('No se pudo crear la categoria.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);
    final categoryName = _nameController.text.trim().isEmpty
        ? 'Nombre de la categoria'
        : _nameController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? 'Aqui aparecera la descripcion resumida de la categoria.'
        : _descriptionController.text.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Anadir categorias'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navyBlue,
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
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
                  label: 'Nombre de la categoria',
                  hintText: 'Ej. Mantenimiento del hogar',
                  scale: scale,
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 14 * scale),
                _StyledTextField(
                  controller: _descriptionController,
                  label: 'Descripcion',
                  hintText: 'Explica que tipo de servicios agrupa',
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
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale,
                    vertical: 8 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FBFD),
                    borderRadius: BorderRadius.circular(14 * scale),
                    border: Border.all(
                      color: AppColors.turquoise.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Categoria activa',
                          style: TextStyle(
                            color: AppColors.navyBlue,
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Switch(
                        value: _isActive,
                        activeColor: AppColors.navyBlue,
                        activeTrackColor: AppColors.turquoise,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16 * scale),
                _InfoCard(
                  scale: scale,
                  message:
                      'La categoria puede crearse vacia. Los servicios se asociaran despues, al crear cada servicio.',
                ),
              ],
            ),
          ),
          SizedBox(height: 14 * scale),
          _SectionCard(
            scale: scale,
            title: 'Vista previa',
            child: _CategoryPreviewCard(
              scale: scale,
              name: categoryName,
              description: description,
              isActive: _isActive,
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
                          'Guardar categoria',
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
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.scale,
    required this.message,
  });

  final double scale;
  final String message;

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
      child: Text(
        message,
        style: TextStyle(
          color: AppColors.navyBlue,
          fontSize: 12 * scale,
          fontWeight: FontWeight.w600,
        ),
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
            'Crea nuevas categorias',
            style: TextStyle(
              color: AppColors.navyBlue,
              fontSize: 19 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            'Define la informacion principal y marca si la categoria estara activa. Los servicios se asignaran cuando se creen.',
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
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final double scale;
  final ValueChanged<String> onChanged;
  final int minLines;
  final int maxLines;

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

class _CategoryPreviewCard extends StatelessWidget {
  const _CategoryPreviewCard({
    required this.scale,
    required this.name,
    required this.description,
    required this.isActive,
  });

  final double scale;
  final String name;
  final String description;
  final bool isActive;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: AppColors.navyBlue,
                    fontSize: 17 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10 * scale,
                  vertical: 6 * scale,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.navyBlue : const Color(0xFFFF2B1F),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isActive ? 'Activa' : 'Inactiva',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
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
          Text(
            'La categoria podra quedarse vacia hasta que se creen servicios para ella.',
            style: TextStyle(
              color: AppColors.navyBlue,
              fontSize: 12 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
