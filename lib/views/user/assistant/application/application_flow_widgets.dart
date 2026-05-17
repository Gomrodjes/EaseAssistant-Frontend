import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/app_colors.dart';
import '../../../../config/measures.dart';

class ApplicationDocumentSlot {
  const ApplicationDocumentSlot({
    required this.keyName,
    required this.label,
  });

  final String keyName;
  final String label;
}

class ApplicationFlowScaffold extends StatelessWidget {
  const ApplicationFlowScaffold({
    super.key,
    required this.titleTop,
    required this.titleBottom,
    required this.description,
    required this.children,
    required this.buttonLabel,
    required this.onContinue,
    required this.isContinueEnabled,
    this.isSubmitting = false,
  });

  final String titleTop;
  final String titleBottom;
  final String description;
  final List<Widget> children;
  final String buttonLabel;
  final VoidCallback? onContinue;
  final bool isContinueEnabled;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 24 * scale,
            vertical: 34 * scale,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  Measures.height(context) - MediaQuery.of(context).padding.top,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 18 * scale),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 34 * scale,
                      fontWeight: FontWeight.w800,
                      height: 1.18,
                      letterSpacing: -0.4,
                    ),
                    children: [
                      TextSpan(
                        text: '$titleTop\n',
                        style: const TextStyle(color: AppColors.purple),
                      ),
                      TextSpan(
                        text: titleBottom,
                        style: const TextStyle(color: AppColors.turquoise),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 28 * scale),
                SizedBox(
                  width: 320 * scale,
                  child: Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5 * scale,
                      fontWeight: FontWeight.w600,
                      height: 1.65,
                      letterSpacing: 0.1,
                      color: AppColors.turquoise,
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),
                Container(
                  width: 176 * scale,
                  height: 2,
                  color: AppColors.turquoise.withOpacity(0.45),
                ),
                SizedBox(height: 34 * scale),
                ...children,
                SizedBox(height: 34 * scale),
                SizedBox(
                  width: double.infinity,
                  height: 54 * scale,
                  child: ElevatedButton(
                    onPressed:
                        isContinueEnabled && !isSubmitting ? onContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.turquoise,
                      disabledBackgroundColor: AppColors.turquoise.withOpacity(
                        0.45,
                      ),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white.withOpacity(0.9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18 * scale),
                      ),
                    ),
                    child: isSubmitting
                        ? SizedBox(
                            width: 20 * scale,
                            height: 20 * scale,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            buttonLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ApplicationUploadTile extends StatelessWidget {
  const ApplicationUploadTile({
    super.key,
    required this.label,
    required this.isCompleted,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isCompleted;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 18 * scale),
      child: Material(
        color: AppColors.turquoise,
        borderRadius: BorderRadius.circular(16 * scale),
        elevation: 4,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16 * scale),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16 * scale,
              vertical: 16 * scale,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 20 * scale,
                    height: 20 * scale,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    isCompleted ? Icons.check : Icons.close,
                    color: isCompleted ? AppColors.navyBlue : AppColors.navyBlue,
                    size: 22 * scale,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ApplicationFlowInfoCard extends StatelessWidget {
  const ApplicationFlowInfoCard({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final scale = Measures.scale(context);

    return Container(
      margin: EdgeInsets.only(bottom: 22 * scale),
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFC),
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(color: AppColors.turquoise.withOpacity(0.3)),
      ),
      child: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 13.5 * scale,
          fontWeight: FontWeight.w600,
          height: 1.5,
          color: AppColors.navyBlue,
        ),
      ),
    );
  }
}
