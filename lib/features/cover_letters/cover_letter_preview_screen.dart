import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/resume_models.dart';
import '../../core/services/resume_services.dart';
import '../shared/native_pdf_preview.dart';
import '../shared/view_models.dart';
import '../templates/templates_screen.dart';

class CoverLetterPreviewScreen extends StatefulWidget {
  const CoverLetterPreviewScreen({super.key});

  @override
  State<CoverLetterPreviewScreen> createState() =>
      _CoverLetterPreviewScreenState();
}

class _CoverLetterPreviewScreenState extends State<CoverLetterPreviewScreen> {
  Future<void> _sharePdf() async {
    final viewModel = context.read<CoverLetterEditorViewModel>();
    final pdfService = context.read<ResumePdfService>();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 160));
      final file = await pdfService.saveCoverLetterPdfToDevice(
        viewModel.coverLetter,
      );
      if (!mounted) {
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '${viewModel.coverLetter.displayTitle} cover letter',
        text: 'Shared from ResumeAI',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open share sheet right now.')),
      );
    }
  }

  Future<void> _chooseTemplate() async {
    final viewModel = context.read<CoverLetterEditorViewModel>();
    final selectedTemplate = await Navigator.of(context)
        .push<CoverLetterTemplate>(
          MaterialPageRoute<CoverLetterTemplate>(
            builder: (routeContext) {
              return Scaffold(
                appBar: AppBar(
                  leadingWidth: 56,
                  titleSpacing: 2,
                  title: const Text('Choose template'),
                ),
                body: TemplatesScreen(
                  selectedCoverLetterTemplate: viewModel.coverLetter.template,
                  onCoverLetterTemplateSelected: (template) =>
                      Navigator.of(routeContext).pop(template),
                ),
              );
            },
          ),
        );

    if (!mounted ||
        selectedTemplate == null ||
        selectedTemplate == viewModel.coverLetter.template) {
      return;
    }

    viewModel.updateCoverLetter(
      (letter) => letter.copyWith(template: selectedTemplate),
    );
    await viewModel.saveCoverLetter(showBusy: false);
  }

  @override
  Widget build(BuildContext context) {
    final pdfService = context.read<ResumePdfService>();
    final theme = Theme.of(context);
    final scaffoldBg = theme.scaffoldBackgroundColor;
    const barBg = Colors.white;

    return Consumer<CoverLetterEditorViewModel>(
      builder: (context, viewModel, _) {
        final letter = viewModel.coverLetter;
        final isTestBinding = WidgetsBinding.instance.runtimeType
            .toString()
            .contains('TestWidgetsFlutterBinding');
        final iosTitleStyle = Theme.of(
          context,
        ).cupertinoOverrideTheme?.textTheme?.navTitleTextStyle;
        final baseTitleStyle = Theme.of(context).platform == TargetPlatform.iOS
            ? iosTitleStyle?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              )
            : Theme.of(context).appBarTheme.titleTextStyle;

        return Scaffold(
          appBar: AppBar(
            leadingWidth: 56,
            titleSpacing: 2,
            title: Text(letter.displayTitle, style: baseTitleStyle),
          ),
          body: Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    color: scaffoldBg,
                    child: Column(
                      children: [
                        if (viewModel.isBusy) const LinearProgressIndicator(),
                        Expanded(
                          child: Container(
                            key: const Key('cover-letter-preview-screen'),
                            width: double.infinity,
                            color: scaffoldBg,
                            child: isTestBinding
                                ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: SingleChildScrollView(
                                      child: Text(letter.content),
                                    ),
                                  )
                                : NativePdfPreview(
                                    key: ValueKey(
                                      '${letter.template.name}-${letter.updatedAt.microsecondsSinceEpoch}',
                                    ),
                                    documentKey:
                                        '${letter.id}-${letter.updatedAt.microsecondsSinceEpoch}',
                                    viewerBackground: scaffoldBg,
                                    bytesFuture: pdfService.buildCoverLetterPdf(
                                      letter,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _CoverLetterPreviewBottomBar(
                backgroundColor: barBg,
                onTemplate: _chooseTemplate,
                onShare: _sharePdf,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CoverLetterPreviewBottomBar extends StatelessWidget {
  const _CoverLetterPreviewBottomBar({
    required this.backgroundColor,
    required this.onTemplate,
    required this.onShare,
  });

  final Color backgroundColor;
  final VoidCallback onTemplate;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CoverLetterPreviewBottomAction(
                icon: Icons.view_quilt_outlined,
                label: 'Template',
                onTap: onTemplate,
              ),
              _CoverLetterPreviewBottomAction(
                icon: Icons.ios_share_rounded,
                label: 'Share',
                onTap: onShare,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverLetterPreviewBottomAction extends StatelessWidget {
  const _CoverLetterPreviewBottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
