import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../../config/measures.dart';
import '../../../models/models.dart';
import '../../../services/address_service.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({
    super.key,
    required this.userId,
  });

  final int userId;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final AddressService _addressService = AddressService();

  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(
    text: 'Espana',
  );
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isPrimary = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _addressService.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _zipCodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    FocusScope.of(context).unfocus();

    if (_streetController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _countryController.text.trim().isEmpty ||
        _zipCodeController.text.trim().isEmpty) {
      _showMessage('Completa calle, ciudad, pais y codigo postal.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await _addressService.createAddress(
        AddressSaveDto(
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          country: _countryController.text.trim(),
          zipCode: _zipCodeController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isPrimary: _isPrimary,
          userId: widget.userId,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(response.data);
    } on AddressException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('No se pudo guardar la direccion.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navyBlue,
        elevation: 0,
        title: const Text('Nueva direccion'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          22 * scale,
          12 * scale,
          22 * scale,
          24 * scale,
        ),
        children: [
          _AddressField(
            controller: _streetController,
            label: 'Calle y numero',
            hint: 'Ej. C/ Jesus Nazareno 16',
            scale: scale,
          ),
          SizedBox(height: 14 * scale),
          _AddressField(
            controller: _cityController,
            label: 'Ciudad',
            hint: 'Ej. Cadiz',
            scale: scale,
          ),
          SizedBox(height: 14 * scale),
          _AddressField(
            controller: _countryController,
            label: 'Pais',
            hint: 'Ej. Espana',
            scale: scale,
          ),
          SizedBox(height: 14 * scale),
          _AddressField(
            controller: _zipCodeController,
            label: 'Codigo postal',
            hint: 'Ej. 11001',
            scale: scale,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 14 * scale),
          _AddressField(
            controller: _descriptionController,
            label: 'Indicaciones',
            hint: 'Portal, piso, referencia...',
            scale: scale,
            maxLines: 3,
          ),
          SizedBox(height: 14 * scale),
          SwitchListTile.adaptive(
            value: _isPrimary,
            activeColor: AppColors.turquoise,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Usar como direccion principal',
              style: TextStyle(
                fontSize: 14 * scale,
                color: AppColors.navyBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
            onChanged: _isSaving
                ? null
                : (value) {
                    setState(() {
                      _isPrimary = value;
                    });
                  },
          ),
          SizedBox(height: 24 * scale),
          SizedBox(
            height: 50 * scale,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8DB0D3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18 * scale),
                ),
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 20 * scale,
                      height: 20 * scale,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Guardar direccion',
                      style: TextStyle(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.scale,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final double scale;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF434343),
          ),
        ),
        SizedBox(height: 8 * scale),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF8FBFD),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16 * scale,
              vertical: 14 * scale,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16 * scale),
              borderSide: const BorderSide(color: Color(0xFFB7D4EA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16 * scale),
              borderSide: const BorderSide(color: Color(0xFFB7D4EA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16 * scale),
              borderSide: const BorderSide(color: AppColors.turquoise),
            ),
          ),
        ),
      ],
    );
  }
}

