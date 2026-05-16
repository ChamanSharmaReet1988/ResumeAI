import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/bottom_sheet_insets.dart';
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
  Set<String> _deletingIds = <String>{};
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

  Future<void> _confirmDeleteFromICloud(ICloudResumeSummary item) async {
    final label = item.isCoverLetter ? 'cover letter' : 'resume';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete from iCloud?'),
          content: Text(
            'Remove "${item.title}" from iCloud? This will not delete the copy on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('Delete $label'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await _deleteFromICloud(item);
  }

  Future<void> _deleteFromICloud(ICloudResumeSummary item) async {
    setState(() => _deletingIds = {..._deletingIds, item.id});
    try {
      await _service.deleteFromICloud(
        id: item.id,
        isCoverLetter: item.isCoverLetter,
      );
      await _loadCloudResumes();
      if (mounted) {
        _showMessage('Removed ${item.title} from iCloud.');
      }
    } on Exception catch (error) {
      if (mounted) {
        _showMessage('Could not delete from iCloud: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _deletingIds = {..._deletingIds}..remove(item.id));
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

  Future<void> _showICloudItemActions({
    required ICloudResumeSummary item,
    required _ICloudItemStatus status,
  }) async {
    final canDownload = switch (status) {
      _ICloudItemStatus.cloudOnly => true,
      _ICloudItemStatus.cloudNewer => true,
      _ICloudItemStatus.localNewer => false,
      _ICloudItemStatus.synced => false,
    };

    final action = await showModalBottomSheet<_ICloudItemAction>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
        final primaryColor = sheetTheme.colorScheme.primary;
        final mutedColor = sheetTheme.colorScheme.onSurfaceVariant;
        final actionTextColor = sheetTheme.colorScheme.onSurface;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: BottomSheetInsets.leftPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: BottomSheetInsets.topSpacing),
                ListTile(
                  leading: Icon(
                    Icons.download_rounded,
                    color: canDownload ? primaryColor : mutedColor,
                  ),
                  title: Text(
                    canDownload ? 'Download' : 'Already downloaded',
                    style: sheetTheme.textTheme.bodyLarge?.copyWith(
                      color: canDownload ? actionTextColor : mutedColor,
                    ),
                  ),
                  enabled: canDownload,
                  onTap: canDownload
                      ? () => Navigator.of(
                          sheetContext,
                        ).pop(_ICloudItemAction.download)
                      : null,
                ),
                ListTile(
                  leading: IconTheme(
                    data: IconThemeData(color: primaryColor),
                    child: const ImageIcon(
                      AssetImage('assets/fonts/delete.png'),
                    ),
                  ),
                  title: Text(
                    'Delete from iCloud',
                    style: sheetTheme.textTheme.bodyLarge?.copyWith(
                      color: actionTextColor,
                    ),
                  ),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_ICloudItemAction.delete),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _ICloudItemAction.download:
        await _downloadItem(item);
      case _ICloudItemAction.delete:
        await _confirmDeleteFromICloud(item);
    }
  }

  Widget _buildICloudItemCard({
    required ICloudResumeSummary item,
    required _ICloudItemStatus status,
    required DateFormat dateFormat,
  }) {
    final isBusy =
        _downloadingIds.contains(item.id) || _deletingIds.contains(item.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isBusy
              ? null
              : () => _showICloudItemActions(item: item, status: status),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: _ICloudItemContent(
              summary: item,
              dateFormat: dateFormat,
              showProgress: isBusy,
            ),
          ),
        ),
      ),
    );
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
                        _buildICloudItemCard(
                          item: item,
                          status: _statusForResume(
                            localResume: localResumeById[item.id],
                            cloudResume: item,
                          ),
                          dateFormat: dateFormat,
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
                        _buildICloudItemCard(
                          item: item,
                          status: _statusForCoverLetter(
                            localLetter: localCoverById[item.id],
                            cloudItem: item,
                          ),
                          dateFormat: dateFormat,
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

enum _ICloudItemAction { download, delete }

class _ICloudItemContent extends StatelessWidget {
  const _ICloudItemContent({
    required this.summary,
    required this.dateFormat,
    required this.showProgress,
  });

  final ICloudResumeSummary summary;
  final DateFormat dateFormat;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = summary.title.trim().isEmpty
        ? (summary.isCoverLetter
            ? 'Untitled Cover Letter'
            : ResumeData.defaultTitle)
        : summary.title.trim();
    final metadataStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) - 3,
      height: 1.2,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Updated: ${dateFormat.format(summary.updatedAt)}',
                style: metadataStyle,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (showProgress)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(
            Icons.arrow_forward_ios_rounded,
            key: Key('icloud-card-arrow-${summary.id}'),
            size: 20,
            color: theme.colorScheme.primary,
          ),
      ],
    );
  }
}