import 'package:ease_assistant_frontend/models/models.dart';
import 'package:ease_assistant_frontend/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_colors.dart';
import '../../config/measures.dart';
import 'type_account.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const List<String> _nationalities = [
    'Espana',
    'Colombia',
    'Mexico',
    'Argentina',
    'Peru',
    'Venezuela',
    'Chile',
    'Otro',
  ];

  final _accountFormKey = GlobalKey<FormState>();
  final _detailsFormKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _biographyController = TextEditingController();

  final _authService = AuthService();

  Gender? _selectedGender;
  String? _selectedNationality;
  DateTime? _selectedBirthDate;
  bool _showAdditionalData = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    _biographyController.dispose();
    _authService.dispose();
    super.dispose();
  }

  Future<void> _goToAdditionalData() async {
    if (_isSubmitting) return;

    final currentState = _accountFormKey.currentState;
    if (currentState == null || !currentState.validate()) {
      return;
    }

    if (_selectedGender == null) {
      _showMessage('Selecciona el sexo.');
      return;
    }

    if (_selectedNationality == null || _selectedNationality!.isEmpty) {
      _showMessage('Selecciona la nacionalidad.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _showAdditionalData = true;
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthDate ?? DateTime(now.year - 18);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (pickedDate == null) return;

    setState(() {
      _selectedBirthDate = pickedDate;
      _birthDateController.text = _formatDate(pickedDate);
    });
  }

  Future<void> _register() async {
    if (_isSubmitting) return;

    final detailsState = _detailsFormKey.currentState;
    if (detailsState == null || !detailsState.validate()) {
      return;
    }

    if (_selectedBirthDate == null) {
      _showMessage('Selecciona la fecha de nacimiento.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userResponse = await _authService.register(
        UserSaveDto(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          dateOfBirth: _selectedBirthDate,
          gender: _selectedGender,
          nationality: _selectedNationality,
          biography: _biographyController.text.trim().isEmpty
              ? null
              : _biographyController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        ),
      );

      if (userResponse.data?.id == null) {
        throw const AuthException('No se pudo obtener el usuario creado.');
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => TypeAccountScreen(
            createdUser: userResponse.data!,
          ),
        ),
      );
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Ha ocurrido un error inesperado al registrar la cuenta.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  void _handleBack() {
    if (_showAdditionalData) {
      setState(() {
        _showAdditionalData = false;
      });
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _handleBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        iconTheme: const IconThemeData(color: AppColors.turquoise),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 26 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 14 * scale),
              _showAdditionalData
                  ? _AdditionalDataStep(
                      scale: scale,
                      formKey: _detailsFormKey,
                      birthDateController: _birthDateController,
                      biographyController: _biographyController,
                      isSubmitting: _isSubmitting,
                      onPickBirthDate: () {
                        _pickBirthDate();
                      },
                      onSubmit: () {
                        _register();
                      },
                    )
                  : _AccountStep(
                      scale: scale,
                      formKey: _accountFormKey,
                      fullNameController: _fullNameController,
                      phoneController: _phoneController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      selectedGender: _selectedGender,
                      selectedNationality: _selectedNationality,
                      nationalities: _nationalities,
                      onGenderChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      onNationalityChanged: (value) {
                        setState(() {
                          _selectedNationality = value;
                        });
                      },
                      onNext: () {
                        _goToAdditionalData();
                      },
                    ),
              SizedBox(height: 24 * scale),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountStep extends StatelessWidget {
  const _AccountStep({
    required this.scale,
    required this.formKey,
    required this.fullNameController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.selectedGender,
    required this.selectedNationality,
    required this.nationalities,
    required this.onGenderChanged,
    required this.onNationalityChanged,
    required this.onNext,
  });

  final double scale;
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final Gender? selectedGender;
  final String? selectedNationality;
  final List<String> nationalities;
  final ValueChanged<Gender?> onGenderChanged;
  final ValueChanged<String?> onNationalityChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Crear Cuenta',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.turquoise,
              fontSize: 31 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 26 * scale),
          Center(
            child: Container(
              width: 102 * scale,
              height: 102 * scale,
              padding: EdgeInsets.all(18 * scale),
              decoration: const BoxDecoration(
                color: Color(0xFF169DEE),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset('assets/images/bloqueado-1.svg'),
            ),
          ),
          SizedBox(height: 28 * scale),
          _RoundedTextField(
            controller: fullNameController,
            hintText: 'Nombre Completo',
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Introduce tu nombre completo.';
              }
              return null;
            },
          ),
          SizedBox(height: 14 * scale),
          Row(
            children: [
              Expanded(
                child: _RoundedDropdownField<Gender>(
                  hintText: 'Sexo',
                  value: selectedGender,
                  items: const [
                    DropdownMenuItem(
                      value: Gender.male,
                      child: Text('Masculino'),
                    ),
                    DropdownMenuItem(
                      value: Gender.female,
                      child: Text('Femenino'),
                    ),
                    DropdownMenuItem(
                      value: Gender.other,
                      child: Text('Otro'),
                    ),
                  ],
                  onChanged: onGenderChanged,
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: _RoundedDropdownField<String>(
                  hintText: 'Nacionalidad',
                  value: selectedNationality,
                  items: nationalities
                      .map(
                        (nationality) => DropdownMenuItem(
                          value: nationality,
                          child: Text(nationality),
                        ),
                      )
                      .toList(),
                  onChanged: onNationalityChanged,
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * scale),
          _RoundedTextField(
            controller: phoneController,
            hintText: 'Telefono',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Introduce tu telefono.';
              }
              return null;
            },
          ),
          SizedBox(height: 14 * scale),
          _RoundedTextField(
            controller: emailController,
            hintText: 'Correo Electronico',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) {
                return 'Introduce tu correo.';
              }
              if (!email.contains('@')) {
                return 'Correo no valido.';
              }
              return null;
            },
          ),
          SizedBox(height: 14 * scale),
          _RoundedTextField(
            controller: passwordController,
            hintText: 'Contrasena',
            obscureText: true,
            validator: (value) {
              if ((value ?? '').length < 6) {
                return 'La contrasena debe tener al menos 6 caracteres.';
              }
              return null;
            },
          ),
          SizedBox(height: 14 * scale),
          _RoundedTextField(
            controller: confirmPasswordController,
            hintText: 'Repetir contrasena',
            obscureText: true,
            validator: (value) {
              if ((value ?? '').isEmpty) {
                return 'Repite tu contrasena.';
              }
              if (value != passwordController.text) {
                return 'Las contrasenas no coinciden.';
              }
              return null;
            },
          ),
          SizedBox(height: 24 * scale),
          _PrimaryButton(
            label: 'Siguiente',
            onPressed: onNext,
          ),
          SizedBox(height: 18 * scale),
          Divider(color: AppColors.turquoise.withValues(alpha: 0.6)),
          SizedBox(height: 14 * scale),
          Text(
            '¿Ya tienes cuenta?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.turquoise,
              fontSize: 15 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Inicia sesion',
              style: GoogleFonts.poppins(
                color: AppColors.purple,
                fontSize: 15 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdditionalDataStep extends StatelessWidget {
  const _AdditionalDataStep({
    required this.scale,
    required this.formKey,
    required this.birthDateController,
    required this.biographyController,
    required this.isSubmitting,
    required this.onPickBirthDate,
    required this.onSubmit,
  });

  final double scale;
  final GlobalKey<FormState> formKey;
  final TextEditingController birthDateController;
  final TextEditingController biographyController;
  final bool isSubmitting;
  final VoidCallback onPickBirthDate;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 30 * scale,
                fontWeight: FontWeight.w800,
              ),
              children: const [
                TextSpan(
                  text: 'Datos\n',
                  style: TextStyle(color: AppColors.purple),
                ),
                TextSpan(
                  text: 'Adicionales',
                  style: TextStyle(color: AppColors.turquoise),
                ),
              ],
            ),
          ),
          SizedBox(height: 26 * scale),
          Row(
            children: [
              Expanded(
                child: _RoundedTextField(
                  controller: birthDateController,
                  hintText: 'Fecha de nacimiento  MM/DD/AAAA',
                  readOnly: true,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Selecciona la fecha de nacimiento.';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 10 * scale),
              InkWell(
                borderRadius: BorderRadius.circular(18 * scale),
                onTap: onPickBirthDate,
                child: Container(
                  width: 48 * scale,
                  height: 48 * scale,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18 * scale),
                    border: Border.all(color: AppColors.navyBlue),
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.navyBlue,
                    size: 22 * scale,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20 * scale),
          Divider(color: AppColors.turquoise.withValues(alpha: 0.65)),
          SizedBox(height: 20 * scale),
          _RoundedTextField(
            controller: biographyController,
            hintText: 'Biografia',
            maxLines: 4,
          ),
          SizedBox(height: 24 * scale),
          Divider(color: AppColors.turquoise.withValues(alpha: 0.65)),
          SizedBox(height: 24 * scale),
          _PrimaryButton(
            label: 'Registrar',
            isLoading: isSubmitting,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _RoundedTextField extends StatelessWidget {
  const _RoundedTextField({
    required this.controller,
    required this.hintText,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      maxLines: obscureText ? 1 : maxLines,
      style: GoogleFonts.poppins(
        fontSize: 12 * scale,
        color: AppColors.navyBlue,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(
          color: const Color(0xFFC9C9C9),
          fontSize: 12 * scale,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 12 * scale,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18 * scale),
          borderSide: const BorderSide(color: AppColors.turquoise),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18 * scale),
          borderSide: const BorderSide(
            color: AppColors.turquoise,
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18 * scale),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18 * scale),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _RoundedDropdownField<T> extends StatelessWidget {
  const _RoundedDropdownField({
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hintText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      style: GoogleFonts.poppins(
        fontSize: 12 * scale,
        color: AppColors.navyBlue,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(
          color: const Color(0xFFC9C9C9),
          fontSize: 12 * scale,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14 * scale,
          vertical: 7 * scale,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18 * scale),
          borderSide: const BorderSide(color: AppColors.turquoise),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18 * scale),
          borderSide: const BorderSide(
            color: AppColors.turquoise,
            width: 1.2,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(18 * scale),
      dropdownColor: Colors.white,
      hint: Text(
        hintText,
        style: GoogleFonts.poppins(
          color: const Color(0xFFC9C9C9),
          fontSize: 12 * scale,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return SizedBox(
      width: double.infinity,
      height: 50 * scale,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.turquoise,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * scale),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 18 * scale,
                height: 18 * scale,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}
