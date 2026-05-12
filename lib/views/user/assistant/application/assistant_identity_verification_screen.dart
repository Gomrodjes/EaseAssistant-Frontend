import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/secure_storage.dart';
import '../../../../models/models.dart';
import '../../../../services/documentation_service.dart';
import '../../../../services/user_service.dart';
import 'application_flow_widgets.dart';
import 'assistant_required_documents_screen.dart';

class AssistantIdentityVerificationScreen extends StatefulWidget {
  const AssistantIdentityVerificationScreen({super.key});

  @override
  State<AssistantIdentityVerificationScreen> createState() =>
      _AssistantIdentityVerificationScreenState();
}

class _AssistantIdentityVerificationScreenState
    extends State<AssistantIdentityVerificationScreen> {
  static const List<ApplicationDocumentSlot> _slots = [
    ApplicationDocumentSlot(
      keyName: 'dniFront',
      label: 'Foto DNI delantera',
    ),
    ApplicationDocumentSlot(
      keyName: 'dniBack',
      label: 'Foto DNI trasera',
    ),
    ApplicationDocumentSlot(
      keyName: 'selfie',
      label: 'Foto de camara',
    ),
  ];

  final DocumentationService _documentationService = DocumentationService();
  final UserService _userService = UserService();

  final Map<String, int> _uploadedDocumentIds = <String, int>{};
  final Set<String> _uploadingKeys = <String>{};

  int? _userId;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _documentationService.dispose();
    _userService.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final token = await SecureStorage.getToken();
      final email = token == null ? '' : SecureStorage.getEmailFromToken(token);
      final usersResponse = await _userService.getAllUsers();

      int? userId;
      for (final user in usersResponse.data ?? <UserResponseDto>[]) {
        if (user.email.trim().toLowerCase() == email.trim().toLowerCase()) {
          userId = user.id;
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        _userId = userId;
        _isLoadingUser = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingUser = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener el usuario autenticado.'),
        ),
      );
    }
  }

  Future<void> _pickAndUpload(
    ApplicationDocumentSlot slot,
    TypeDocument documentType,
  ) async {
    final userId = _userId;
    if (userId == null || _uploadingKeys.contains(slot.keyName)) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: false,
    );

    final filePath = result?.files.single.path;
    if (filePath == null || filePath.isEmpty) {
      return;
    }

    setState(() {
      _uploadingKeys.add(slot.keyName);
    });

    try {
      final response = await _documentationService.createDocumentation(
        userId: userId,
        type: documentType,
        file: File(filePath),
      );

      final createdDocumentation = response.data;
      final documentationId = createdDocumentation?.id;

      if (!mounted) return;

      if (documentationId == null) {
        throw const DocumentationServiceException(
          'No se pudo identificar el documento subido.',
        );
      }

      setState(() {
        _uploadedDocumentIds[slot.keyName] = documentationId;
      });
    } on DocumentationServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo subir el documento seleccionado.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingKeys.remove(slot.keyName);
        });
      }
    }
  }

  bool get _canContinue =>
      _userId != null &&
      _slots.every((slot) => _uploadedDocumentIds.containsKey(slot.keyName));

  void _goToNextStep() {
    final userId = _userId;
    if (!_canContinue || userId == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AssistantRequiredDocumentsScreen(
          userId: userId,
          identityDocumentationIds: _uploadedDocumentIds.values.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ApplicationFlowScaffold(
      titleTop: 'Verificacion',
      titleBottom: 'de Identidad',
      description:
          'Para proteger a las personas,\nnecesitamos confirmar tu identidad.',
      buttonLabel: 'Continuar',
      onContinue: _goToNextStep,
      isContinueEnabled: _canContinue,
      isSubmitting: _isLoadingUser,
      children: [
        const ApplicationFlowInfoCard(
          message:
              'Sube una foto clara del DNI por delante y por detras, junto con una imagen de camara para completar la verificacion.',
        ),
        ..._slots.map(
          (slot) => ApplicationUploadTile(
            label: slot.label,
            isCompleted: _uploadedDocumentIds.containsKey(slot.keyName),
            isLoading: _uploadingKeys.contains(slot.keyName),
            onTap: () => _pickAndUpload(
              slot,
              switch (slot.keyName) {
                'dniFront' => TypeDocument.dniFront,
                'dniBack' => TypeDocument.dniBack,
                _ => TypeDocument.selfie,
              },
            ),
          ),
        ),
      ],
    );
  }
}
