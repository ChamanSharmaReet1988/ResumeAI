import 'package:flutter/material.dart';

import '../../core/bottom_sheet_insets.dart';

enum ResumeShareFormat { pdf, docx }

/// Bottom sheet: share resume as PDF or Docs (matches app action sheets).
Future<ResumeShareFormat?> showResumeShareFormatSheet(BuildContext context) {
  return showModalBottomSheet<ResumeShareFormat>(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    builder: (sheetContext) {
      final iconColor = Theme.of(sheetContext).colorScheme.primary;
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
                title: const Text('PDF'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ResumeShareFormat.pdf),
              ),
              ListTile(
                key: const Key('share-resume-docx-option'),
                leading: Icon(Icons.description_outlined, color: iconColor),
                title: const Text('DOCX'),
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
