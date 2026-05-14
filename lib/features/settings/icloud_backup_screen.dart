import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/resume_models.dart';
import '../../core/services/icloud_resume_service.dart';
import '../../core/services/resume_services.dart';
import '../shared/view_models.dart';

class ICloudBackupScreen extends StatefulWidget {
  const ICloudBackupScreen({super.key});

  @override
  State<ICloudBackupScreen> createState() => _ICloudBackupScreenState();
}

class _ICloudBackupScreenState extends State<ICloudBackupScreen> {
  bool _isLoading = true;
  bool _isAvailable = false;
  bool _isSyncing = false;
  Set<String> _downloadingIds = <String>{};
  List<ICloudResumeSummary> _cloudResumes = const [];

  ICloudResumeService get _service => context.read<ICloudResumeService>();

  @override
  void initState() {
    super.initState();
    _loadCloudResumes();
  }

  Future<void> _loadCloudResumes() async {
    setState(() => _isLoading = true);
    try {
      final isAvailable = await _service.isAvailable();
      final items = isAvailable
          ? await _service.listResumes()
          : const <ICloudResumeSummary>[];
      if (!mounted) {
        return;
      }
      setState(() {
        _isAvailable = isAvailable;
        _cloudResumes = items;
      });
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isAvailable = false;
        _cloudResumes = const [];
      });
      _showMessage('Could not load iCloud resumes: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncToICloud() async {
    final library = context.read<ResumeLibraryViewModel>();
    final repository = context.read<ResumeRepository>();
    final localResumes = library.resumes;
    if (localResumes.isEmpty) {
      _showMessage('No local resumes available to sync.');
      return;
    }

    setState(() => _isSyncing = true);
    try {
      final cloudById = {for (final item in _cloudResumes) item.id: item};
      final resumesToUpload = localResumes.where((resume) {
        final cloud = cloudById[resume.id];
        return cloud == null || !cloud.updatedAt.isAfter(resume.updatedAt);
      }).toList();
      final skippedCount = localResumes.length - resumesToUpload.length;

      if (resumesToUpload.isEmpty) {
        _showMessage('All resumes are already up to date in iCloud.');
        return;
      }

      final uploadedIds = await _service.uploadResumes(resumesToUpload);
      final syncedAt = DateTime.now();
      for (final resume in localResumes) {
        if (!uploadedIds.contains(resume.id)) {
          continue;
        }
        await repository.upsertResume(resume.copyWith(lastSyncedAt: syncedAt));
      }

      await library.loadResumes();
      await _loadCloudResumes();

      if (!mounted) {
        return;
      }

      final uploadedCount = uploadedIds.length;
      if (skippedCount > 0) {
        _showMessage(
          'Synced $uploadedCount resumes. $skippedCount newer iCloud version${skippedCount == 1 ? '' : 's'} left untouched.',
        );
      } else {
        _showMessage('Synced $uploadedCount resumes to iCloud.');
      }
    } on Exception catch (error) {
      if (mounted) {
        _showMessage('Could not sync to iCloud: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _downloadResume(ICloudResumeSummary item) async {
    setState(() => _downloadingIds = {..._downloadingIds, item.id});
    try {
      final repository = context.read<ResumeRepository>();
      final library = context.read<ResumeLibraryViewModel>();
      final downloaded = await _service.downloadResume(item.id);
      await repository.upsertResume(
        downloaded.copyWith(lastSyncedAt: DateTime.now()),
      );
      await library.loadResumes();
      await _loadCloudResumes();
      if (mounted) {
        _showMessage('Downloaded ${item.title}.');
      }
    } on Exception catch (error) {
      if (mounted) {
        _showMessage('Could not download resume: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingIds = {..._downloadingIds}..remove(item.id));
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y');
    final library = context.watch<ResumeLibraryViewModel>();
    final localById = {for (final item in library.resumes) item.id: item};

    return Scaffold(
      appBar: AppBar(title: const Text('iCloud Backup')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCloudResumes,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_done_outlined,
                            size: 22,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Sync to iCloud',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          FilledButton(
                            onPressed: !_isAvailable || _isSyncing
                                ? null
                                : _syncToICloud,
                            child: _isSyncing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Sync'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isAvailable)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'iCloud is not available on this device right now. Make sure iCloud Drive is enabled and you are signed in with the correct Apple ID.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else if (_cloudResumes.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No resumes are stored in iCloud yet.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else ...[
                    Text(
                      'Resumes in iCloud',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    for (final item in _cloudResumes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: _CloudResumeRow(
                              summary: item,
                              status: _statusFor(
                                localResume: localById[item.id],
                                cloudResume: item,
                              ),
                              dateFormat: dateFormat,
                              isBusy: _downloadingIds.contains(item.id),
                              onDownload: () => _downloadResume(item),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  _CloudResumeStatus _statusFor({
    required ResumeData? localResume,
    required ICloudResumeSummary cloudResume,
  }) {
    if (localResume == null) {
      return _CloudResumeStatus.cloudOnly;
    }
    if (cloudResume.updatedAt.isAfter(localResume.updatedAt)) {
      return _CloudResumeStatus.cloudNewer;
    }
    if (localResume.updatedAt.isAfter(cloudResume.updatedAt)) {
      return _CloudResumeStatus.localNewer;
    }
    return _CloudResumeStatus.synced;
  }
}

enum _CloudResumeStatus { cloudOnly, cloudNewer, localNewer, synced }

class _CloudResumeRow extends StatelessWidget {
  const _CloudResumeRow({
    required this.summary,
    required this.status,
    required this.dateFormat,
    required this.isBusy,
    required this.onDownload,
  });

  final ICloudResumeSummary summary;
  final _CloudResumeStatus status;
  final DateFormat dateFormat;
  final bool isBusy;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = summary.title.trim().isEmpty
        ? ResumeData.defaultTitle
        : summary.title.trim();
    final subtitleStyle = theme.textTheme.bodySmall;

    final (statusText, buttonText, isDownloadEnabled) = switch (status) {
      _CloudResumeStatus.cloudOnly => ('Cloud only', 'Download', true),
      _CloudResumeStatus.cloudNewer => ('Update available', 'Download', true),
      _CloudResumeStatus.localNewer => ('Local newer', 'Up to date', false),
      _CloudResumeStatus.synced => ('Synced', 'Up to date', false),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(
                'Created ${dateFormat.format(summary.createdAt)}',
                style: subtitleStyle,
              ),
              const SizedBox(height: 2),
              Text(
                'Updated ${dateFormat.format(summary.updatedAt)}',
                style: subtitleStyle,
              ),
              const SizedBox(height: 8),
              Text(statusText, style: subtitleStyle),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: !isDownloadEnabled || isBusy ? null : onDownload,
          child: isBusy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(buttonText),
        ),
      ],
    );
  }
}
