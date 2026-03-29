import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/resume_preview_card.dart';
import '../shared/view_models.dart';

class ResumePreviewScreen extends StatefulWidget {
  const ResumePreviewScreen({super.key});

  @override
  State<ResumePreviewScreen> createState() => _ResumePreviewScreenState();
}

class _ResumePreviewScreenState extends State<ResumePreviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<ResumeEditorViewModel>().analyzeResume();
    });
  }

  Future<void> _downloadResume() async {
    final path = await context.read<ResumeEditorViewModel>().downloadPdf();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('PDF saved to $path')));
  }

  Future<void> _shareResume() async {
    await context.read<ResumeEditorViewModel>().sharePdf();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Share sheet opened.')));
  }

  Future<void> _printResume() async {
    await context.read<ResumeEditorViewModel>().printPdf();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ResumeEditorViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Resume preview')),
          body: SafeArea(
            child: Column(
              children: [
                if (viewModel.isBusy) const LinearProgressIndicator(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResumePreviewCard(resume: viewModel.resume),
                        const SizedBox(height: 16),
                        _PreviewScoreCard(viewModel: viewModel),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                FilledButton.tonal(
                                  onPressed: viewModel.isBusy
                                      ? null
                                      : _downloadResume,
                                  child: const Text('Download PDF'),
                                ),
                                OutlinedButton(
                                  onPressed: viewModel.isBusy
                                      ? null
                                      : _shareResume,
                                  child: const Text('Share resume'),
                                ),
                                OutlinedButton(
                                  onPressed: viewModel.isBusy
                                      ? null
                                      : _printResume,
                                  child: const Text('Print'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PreviewScoreCard extends StatelessWidget {
  const _PreviewScoreCard({required this.viewModel});

  final ResumeEditorViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final analysis = viewModel.analysis;
    final atsCompatibility =
        analysis?.atsCompatibility ?? viewModel.resume.completionRatio;
    final score = analysis?.score ?? (atsCompatibility * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ATS score',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 8,
                      ),
                      Center(
                        child: Text(
                          '$score',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'ATS compatibility ${(atsCompatibility * 100).round()}%'
                    '${analysis == null ? '.' : ' with ${analysis.missingSkills.length} missing skill gap${analysis.missingSkills.length == 1 ? '' : 's'}.'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
