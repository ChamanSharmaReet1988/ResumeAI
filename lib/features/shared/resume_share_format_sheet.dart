import 'package:flutter/material.dart';
import 'package:resume_app/l10n/l10n_ext.dart';

import '../../core/bottom_sheet_insets.dart';

enum ResumeShareFormat { pdf, docx }

/// Bottom sheet: share resume as PDF or Docs (matches app action sheets).
Future<ResumeShareFormat?> showResumeShareFormatSheet(BuildContext context) {
  return showModalBottomSheet<ResumeShareFormat>(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    builder: (sheetContext) {
      final iconColor = Theme.of(sheetContext).colorScheme.primary;
      final l10n = sheetContext.l10n;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: BottomSheetInsets.leftPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: BottomSheetInsets.topSpacing),
              ListTile(
                key: const Key('share-resume-pdf-option'),
                leading: Icon(Icons.picture_as_pdf_outlined, color: iconColor),
                title: Text(l10n.shareFormatPdf),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ResumeShareFormat.pdf),
              ),
              ListTile(
                key: const Key('share-resume-docx-option'),
                leading: Icon(Icons.description_outlined, color: iconColor),
                title: Text(l10n.shareFormatDocx),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ResumeShareFormat.docx),
              ),
            ],
          ),
        ),
      );
    },
  );
}
