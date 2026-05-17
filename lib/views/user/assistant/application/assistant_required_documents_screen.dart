import 'dart:io';

import 'package:ease_assistant_frontend/views/user/assistant/application/assistant_profile_categories_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../models/models.dart';
import '../../../../services/application_service.dart';
import '../../../../services/documentation_service.dart';
import 'application_flow_widgets.dart';

class AssistantRequiredDocumentsScreen extends StatefulWidget {
  const AssistantRequiredDocumentsScreen({
    super.key,
    required this.userId,
    required this.identityDocumentationIds,
  });

  final int userId;
  final List<int> identityDocumentationIds;

  @override
  State<AssistantRequiredDocumentsScreen> createState() =>
      _AssistantRequiredDocumentsScreenState();
}

class _AssistantRequiredDocumentsScreenState
    extends State<AssistantRequiredDocumentsScreen> {
  static const List<ApplicationDocumentSlot> _slots = [
    ApplicationDocumentSlot(
      keyName: 'backgroundCheck',
      label: 'Certificado de antecedentes penales',
    ),
    ApplicationDocumentSlot(
      keyName: 'socialSecurity',
      label: 'Documento de la Seguridad Social',
    ),
    ApplicationDocumentSlot(
      keyName: 'training',
      label: 'Certificados de formacion',
    ),
  ];

  final DocumentationService _documentationService = DocumentationService();
  final ApplicationService _applicationService = ApplicationService();

  final Map<String, int> _uploadedDocumentIds = <String, int>{};
  final Set<String> _uploadingKeys = <String>{};

  bool _isSubmitting = false;

  @override
  void dispose() {
    _documentationService.dispose();
    _applicationService.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload(
    ApplicationDocumentSlot slot,
    TypeDocument documentType,
  ) async {
    if (_uploadingKeys.contains(slot.keyName) || _isSubmitting) {
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
        userId: widget.userId,
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
      _slots.every((slot) => _uploadedDocumentIds.containsKey(slot.keyName));

  Future<void> _submitApplication() async {
    if (!_canContinue || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = ApplicationSaveDto(
        userId: widget.userId,
        documentationsIds: [
          ...widget.identityDocumentationIds,
          ..._uploadedDocumentIds.values,
        ],
      );

      await _applicationService.createApplication(request);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => AssistantProfileCategoriesScreen(userId: widget.userId),
        ),
        (route) => false,
      );
    } on ApplicationServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo enviar la application.'),
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
      titleTop: 'Documentacion',
      titleBottom: 'Necesaria',
      description:
          'Sube la documentacion que necesitamos\npara revisar tu perfil de asistente.',
      buttonLabel: 'Continuar',
      onContinue: _submitApplication,
      isContinueEnabled: _canContinue,
      isSubmitting: _isSubmitting,
      children: [
        const ApplicationFlowInfoCard(
          message:
              'Necesitamos estos tres documentos para poder revisar y validar tu solicitud completa.',
        ),
        ..._slots.map(
          (slot) => ApplicationUploadTile(
            label: slot.label,
            isCompleted: _uploadedDocumentIds.containsKey(slot.keyName),
            isLoading: _uploadingKeys.contains(slot.keyName),
            onTap: () => _pickAndUpload(
              slot,
              switch (slot.keyName) {
                'backgroundCheck' =>
                  TypeDocument.backgroundCheckCertificate,
                'socialSecurity' => TypeDocument.socialSecurityDocument,
                _ => TypeDocument.trainingCertificate,
              },
            ),
          ),
        ),
      ],
    );
  }
}
