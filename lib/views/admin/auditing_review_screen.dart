import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_colors.dart';
import '../../config/measures.dart';
import '../../models/models.dart';
import '../../services/application_service.dart';
import '../../services/documentation_service.dart';

class AuditingReviewScreen extends StatefulWidget {
  const AuditingReviewScreen({
    super.key,
    required this.user,
  });

  final UserResponseDto user;

  @override
  State<AuditingReviewScreen> createState() => _AuditingReviewScreenState();
}

class _AuditingReviewScreenState extends State<AuditingReviewScreen> {
  final ApplicationService _applicationService = ApplicationService();
  final DocumentationService _documentationService = DocumentationService();
  final TextEditingController _reviewController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  ApplicationResponseDto? _application;
  List<DocumentationResponseDto> _documentations = const [];

  @override
  void initState() {
    super.initState();
    _loadReviewData();
  }

  @override
  void dispose() {
    _applicationService.dispose();
    _documentationService.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadReviewData() async {
    final userId = widget.user.id;
    if (userId == null) {
      setState(() {
        _errorMessage = 'No se pudo identificar el usuario.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final applicationsResponse = await _applicationService.getAllApplications();
      final documentationResponse = await _documentationService
          .getAllDocumentationByUser(userId);

      final applications = applicationsResponse.data ?? <ApplicationResponseDto>[];
      ApplicationResponseDto? application;
      for (final item in applications) {
        if (item.userId == userId && item.state == StateApplication.pending) {
          application = item;
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        _application = application;
        _documentations = documentationResponse.data ?? <DocumentationResponseDto>[];
        _isLoading = false;
        _reviewController.text = application?.reviewMessage ?? '';
        if (_application == null) {
          _errorMessage = 'Este usuario no tiene una application pendiente.';
        }
      });
    } on ApplicationServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } on DocumentationServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo cargar la revision.';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitDecision(bool approved) async {
    final applicationId = _application?.id;
    if (_isSubmitting || applicationId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = ApplicationReviewDto(
        reviewMessage: _reviewController.text.trim(),
      );

      if (approved) {
        await _applicationService.approveApplication(applicationId, request);
      } else {
        await _applicationService.denyApplication(applicationId, request);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? 'Application aceptada correctamente.'
                : 'Application denegada correctamente.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } on ApplicationServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar la application.'),
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

  Future<void> _confirmDecision(bool approved) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final scale = Measures.scale(context);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20 * scale),
          ),
          title: Text(
            approved ? 'Confirmar aceptacion' : 'Confirmar denegacion',
            style: TextStyle(
              color: AppColors.navyBlue,
              fontSize: 18 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            approved
                ? 'Estas seguro de aceptar esta aplicacion?'
                : 'Estas seguro de denegar esta aplicacion?',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14 * scale,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(approved ? 'Aceptar' : 'Denegar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _submitDecision(approved);
    }
  }

  Future<void> _openDocumentation(DocumentationResponseDto documentation) async {
    final documentationId = documentation.id;
    if (documentationId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar el documento.'),
        ),
      );
      return;
    }

    final documentUri = _documentationService.getDocumentationFileUri(
      documentationId,
    );

    final launched = await launchUrl(
      documentUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo abrir el documento ${documentation.originalFileName}.',
          ),
        ),
      );
    }
  }

  String _documentTypeLabel(DocumentationResponseDto documentation) {
    switch (documentation.type) {
      case TypeDocument.dni:
      case TypeDocument.passport:
        return 'Fotos de identificacion';
      case TypeDocument.backgroundCheckCertificate:
        return 'Certificado de antecedente';
      case TypeDocument.reta:
        return 'Numero Seguridad Social';
      case TypeDocument.other:
        return 'Certificado de formacion';
      case null:
        return documentation.originalFileName.isNotEmpty
            ? documentation.originalFileName
            : 'Documento';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.turquoise,
          onRefresh: _loadReviewData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              18 * scale,
              28 * scale,
              18 * scale,
              24 * scale,
            ),
            children: [
              if (_isLoading)
                SizedBox(
                  height: Measures.height(context) * 0.75,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.turquoise,
                    ),
                  ),
                )
              else ...[
                Text(
                  'Revision',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.navyBlue,
                    fontSize: 22 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  widget.user.fullName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.navyBlue,
                    fontSize: 22 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 18 * scale),
                if (_errorMessage != null)
                  Column(
                    children: [
                      _ReviewFeedbackCard(
                        message: _errorMessage!,
                        scale: scale,
                      ),
                      SizedBox(height: 18 * scale),
                      _DecisionButton(
                        label: 'Volver',
                        scale: scale,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  )
                else ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16 * scale,
                      vertical: 18 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.navyBlue,
                      borderRadius: BorderRadius.circular(28 * scale),
                    ),
                    child: Column(
                      children: _documentations.isEmpty
                          ? [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 22 * scale,
                                ),
                                child: Text(
                                  'No hay documentacion disponible.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15 * scale,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ]
                          : _documentations
                              .map(
                                (documentation) => Padding(
                                  padding: EdgeInsets.only(bottom: 14 * scale),
                                  child: _DocumentationButton(
                                    label: _documentTypeLabel(documentation),
                                    scale: scale,
                                    onTap: () => _openDocumentation(
                                      documentation,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  SizedBox(height: 22 * scale),
                  Container(
                    height: 200 * scale,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20 * scale),
                      border: Border.all(
                        color: AppColors.turquoise.withOpacity(0.65),
                      ),
                    ),
                    child: TextField(
                      controller: _reviewController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'Respuesta de la revision',
                        hintStyle: TextStyle(
                          color: Colors.black38,
                          fontSize: 14 * scale,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14 * scale),
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * scale),
                  Row(
                    children: [
                      Expanded(
                        child: _DecisionButton(
                          label: 'Aceptar',
                          scale: scale,
                          isLoading: _isSubmitting,
                          onTap: () => _confirmDecision(true),
                        ),
                      ),
                      SizedBox(width: 10 * scale),
                      Expanded(
                        child: _DecisionButton(
                          label: 'Denegar',
                          scale: scale,
                          isLoading: _isSubmitting,
                          onTap: () => _confirmDecision(false),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14 * scale),
                  _DecisionButton(
                    label: 'Volver',
                    scale: scale,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentationButton extends StatelessWidget {
  const _DocumentationButton({
    required this.label,
    required this.scale,
    required this.onTap,
  });

  final String label;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16 * scale),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 14 * scale,
          vertical: 12 * scale,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16 * scale),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.navyBlue,
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward,
              color: AppColors.navyBlue,
              size: 24 * scale,
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    required this.label,
    required this.scale,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final double scale;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46 * scale,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * scale),
          ),
          elevation: 0,
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
                style: TextStyle(
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _ReviewFeedbackCard extends StatelessWidget {
  const _ReviewFeedbackCard({
    required this.message,
    required this.scale,
  });

  final String message;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFC),
        borderRadius: BorderRadius.circular(22 * scale),
        border: Border.all(
          color: AppColors.turquoise.withOpacity(0.35),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.navyBlue,
          fontSize: 15 * scale,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
