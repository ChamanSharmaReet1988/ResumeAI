import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/resume_models.dart';
import '../../core/services/app_preferences.dart';
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
  bool _autoSyncEnabled = false;
  Set<String> _downloadingIds = <String>{};
  List<ICloudResumeSummary> _cloudItems = const [];

  ICloudResumeService get _service => context.read<ICloudResumeService>();
  AppPreferences get _preferences => context.read<AppPreferences>();

  @override
  void initState() {
    super.initState();
    _autoSyncEnabled = _preferences.iCloudAutoSyncEnabled;
    _loadCloudResumes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          context.read<CoverLetterLibraryViewModel>().loadCoverLetters(),
        );
      }
    });
  }

  Future<void> _setAutoSyncEnabled(bool value) async {
    await _preferences.setICloudAutoSyncEnabled(value);
    if (!mounted) {
      return;
    }
    setState(() => _autoSyncEnabled = value);
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
        _cloudItems = items;
      });
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isAvailable = false;
        _cloudItems = const [];
      });
      _showMessage('Could not load iCloud items: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncToICloud() async {
    final resumeLibrary = context.read<ResumeLibraryViewModel>();
    final coverLibrary = context.read<CoverLetterLibraryViewModel>();
    final repository = context.read<ResumeRepository>();
    final localResumes = resumeLibrary.resumes;
    await coverLibrary.loadCoverLetters();
    final localCoverLetters = coverLibrary.coverLetters;

    if (localResumes.isEmpty && localCoverLetters.isEmpty) {
      _showMessage('No local resumes or cover letters available to sync.');
      return;
    }

    setState(() => _isSyncing = true);
    try {
      final cloudResumeById = {
        for (final item in _cloudItems)
          if (!item.isCoverLetter) item.id: item,
      };
      final cloudCoverById = {
        for (final item in _cloudItems)
          if (item.isCoverLetter) item.id: item,
      };

      final resumesToUpload = localResumes.where((resume) {
        final cloud = cloudResumeById[resume.id];
        return cloud == null || !cloud.updatedAt.isAfter(resume.updatedAt);
      }).toList();
      final lettersToUpload = localCoverLetters.where((letter) {
        final cloud = cloudCoverById[letter.id];
        return cloud == null || !cloud.updatedAt.isAfter(letter.updatedAt);
      }).toList();

      final resumeSkipped = localResumes.length - resumesToUpload.length;
      final letterSkipped =
          localCoverLetters.length - lettersToUpload.length;

      if (resumesToUpload.isEmpty && lettersToUpload.isEmpty) {
        _showMessage('Everything is already up to date in iCloud.');
        return;
      }

      final uploadedResumeIds = resumesToUpload.isEmpty
          ? const <String>[]
          : await _service.uploadResumes(resumesToUpload);
      final uploadedLetterIds = lettersToUpload.isEmpty
          ? const <String>[]
          : await _service.uploadCoverLetters(lettersToUpload);

      final syncedAt = DateTime.now();
      for (final resume in localResumes) {
        if (!uploadedResumeIds.contains(resume.id)) {
          continue;
        }
        await repository.upsertResume(
          resume.copyWith(lastSyncedAt: syncedAt),
          scheduleAutoSync: false,
        );
      }
      for (final letter in localCoverLetters) {
        if (!uploadedLetterIds.contains(letter.id)) {
          continue;
        }
        await repository.upsertCoverLetter(
          letter.copyWith(lastSyncedAt: syncedAt),
          scheduleAutoSync: false,
        );
      }

      await resumeLibrary.loadResumes();
      await coverLibrary.loadCoverLetters();
      await _loadCloudResumes();

      if (!mounted) {
        return;
      }

      final resumeCount = uploadedResumeIds.length;
      final letterCount = uploadedLetterIds.length;
      final parts = <String>[];
      if (resumeCount > 0) {
        parts.add(
          '$resumeCount resume${resumeCount == 1 ? '' : 's'}',
        );
      }
      if (letterCount > 0) {
        parts.add(
          '$letterCount cover letter${letterCount == 1 ? '' : 's'}',
        );
      }
      final uploadedSummary = parts.join(' and ');
      final skipped = resumeSkipped + letterSkipped;
      if (skipped > 0) {
        _showMessage(
          'Synced $uploadedSummary. $skipped newer iCloud item${skipped == 1 ? '' : 's'} left untouched.',
        );
      } else {
        _showMessage('Synced $uploadedSummary to iCloud.');
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

  Future<void> _downloadItem(ICloudResumeSummary item) async {
    setState(() => _downloadingIds = {..._downloadingIds, item.id});
    try {
      final repository = context.read<ResumeRepository>();
      final resumeLibrary = context.read<ResumeLibraryViewModel>();
      final coverLibrary = context.read<CoverLetterLibraryViewModel>();

      if (item.isCoverLetter) {
        final downloaded = await _service.downloadCoverLetter(item.id);
        await repository.upsertCoverLetter(
          downloaded.copyWith(lastSyncedAt: DateTime.now()),
          scheduleAutoSync: false,
        );
        await coverLibrary.loadCoverLetters();
      } else {
        final downloaded = await _service.downloadResume(item.id);
        await repository.upsertResume(
          downloaded.copyWith(lastSyncedAt: DateTime.now()),
          scheduleAutoSync: false,
        );
        await resumeLibrary.loadResumes();
      }
      await _loadCloudResumes();
      if (mounted) {
        _showMessage('Downloaded ${item.title}.');
      }
    } on Exception catch (error) {
      if (mounted) {
        _showMessage('Could not download: $error');
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
    final resumeLibrary = context.watch<ResumeLibraryViewModel>();
    final coverLibrary = context.watch<CoverLetterLibraryViewModel>();
    final localResumeById = {for (final r in resumeLibrary.resumes) r.id: r};
    final localCoverById = {
      for (final c in coverLibrary.coverLetters) c.id: c,
    };

    final cloudResumes =
        _cloudItems.where((e) => !e.isCoverLetter).toList(growable: false);
    final cloudCoverLetters =
        _cloudItems.where((e) => e.isCoverLetter).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('iCloud backup')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await context.read<CoverLetterLibraryViewModel>().loadCoverLetters();
                await _loadCloudResumes();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                          Expanded(
                            child: Text(
                              'Auto sync',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          Theme(
                            data: theme.copyWith(
                              switchTheme: SwitchThemeData(
                                thumbColor:
                                    WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return theme.colorScheme.onPrimary;
                                  }
                                  return theme.colorScheme.outline;
                                }),
                                trackColor:
                                    WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return theme.colorScheme.primary;
                                  }
                                  return theme.colorScheme
                                      .surfaceContainerHighest;
                                }),
                                trackOutlineColor:
                                    WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.transparent;
                                  }
                                  return theme.colorScheme.outlineVariant;
                                }),
                              ),
                            ),
                            child: Switch(
                              value: _autoSyncEnabled,
                              onChanged: _isAvailable
                                  ? _setAutoSyncEnabled
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!_autoSyncEnabled) ...[
                    const SizedBox(height: 12),
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
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 34),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: !_isAvailable || _isSyncing
                                  ? null
                                  : _syncToICloud,
                              child: _isSyncing
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
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
                  ],
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
                  else if (cloudResumes.isEmpty && cloudCoverLetters.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No resumes or cover letters are stored in iCloud yet.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else ...[
                    if (cloudResumes.isNotEmpty) ...[
                      Text(
                        'Resumes in iCloud',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      for (final item in cloudResumes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: _ICloudItemRow(
                                summary: item,
                                status: _statusForResume(
                                  localResume: localResumeById[item.id],
                                  cloudResume: item,
                                ),
                                dateFormat: dateFormat,
                                isBusy: _downloadingIds.contains(item.id),
                                onDownload: () => _downloadItem(item),
                              ),
                            ),
                          ),
                        ),
                      if (cloudCoverLetters.isNotEmpty) const SizedBox(height: 8),
                    ],
                    if (cloudCoverLetters.isNotEmpty) ...[
                      Text(
                        'Cover letters in iCloud',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      for (final item in cloudCoverLetters)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: _ICloudItemRow(
                                summary: item,
                                status: _statusForCoverLetter(
                                  localLetter: localCoverById[item.id],
                                  cloudItem: item,
                                ),
                                dateFormat: dateFormat,
                                isBusy: _downloadingIds.contains(item.id),
                                onDownload: () => _downloadItem(item),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  _ICloudItemStatus _statusForResume({
    required ResumeData? localResume,
    required ICloudResumeSummary cloudResume,
  }) {
    if (localResume == null) {
      return _ICloudItemStatus.cloudOnly;
    }
    if (cloudResume.updatedAt.isAfter(localResume.updatedAt)) {
      return _ICloudItemStatus.cloudNewer;
    }
    if (localResume.updatedAt.isAfter(cloudResume.updatedAt)) {
      return _ICloudItemStatus.localNewer;
    }
    return _ICloudItemStatus.synced;
  }

  _ICloudItemStatus _statusForCoverLetter({
    required CoverLetterData? localLetter,
    required ICloudResumeSummary cloudItem,
  }) {
    if (localLetter == null) {
      return _ICloudItemStatus.cloudOnly;
    }
    if (cloudItem.updatedAt.isAfter(localLetter.updatedAt)) {
      return _ICloudItemStatus.cloudNewer;
    }
    if (localLetter.updatedAt.isAfter(cloudItem.updatedAt)) {
      return _ICloudItemStatus.localNewer;
    }
    return _ICloudItemStatus.synced;
  }
}

enum _ICloudItemStatus { cloudOnly, cloudNewer, localNewer, synced }

class _ICloudItemRow extends StatelessWidget {
  const _ICloudItemRow({
    required this.summary,
    required this.status,
    required this.dateFormat,
    required this.isBusy,
    required this.onDownload,
  });

  final ICloudResumeSummary summary;
  final _ICloudItemStatus status;
  final DateFormat dateFormat;
  final bool isBusy;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = summary.title.trim().isEmpty
        ? (summary.isCoverLetter
            ? 'Untitled Cover Letter'
            : ResumeData.defaultTitle)
        : summary.title.trim();
    final metadataStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) - 2,
      height: 1.2,
    );

    final (buttonText, isDownloadEnabled) = switch (status) {
      _ICloudItemStatus.cloudOnly => ('Download', true),
      _ICloudItemStatus.cloudNewer => ('Download', true),
      _ICloudItemStatus.localNewer => ('Downloaded', false),
      _ICloudItemStatus.synced => ('Downloaded', false),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(
                'Updated: ${dateFormat.format(summary.updatedAt)}',
                style: metadataStyle,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: !isDownloadEnabled || isBusy ? null : onDownload,
          child: isBusy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(buttonText),
        ),
      ],
    );
  }
}