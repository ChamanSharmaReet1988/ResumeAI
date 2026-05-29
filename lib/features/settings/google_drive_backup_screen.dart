import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/bottom_sheet_insets.dart';
import '../../core/models/resume_models.dart';
import '../../core/services/app_preferences.dart';
import '../../core/services/google_drive_resume_service.dart';
import '../../core/services/resume_services.dart';
import '../premium/premium_gate.dart';
import '../shared/view_models.dart';

class GoogleDriveBackupScreen extends StatefulWidget {
  const GoogleDriveBackupScreen({super.key});

  @override
  State<GoogleDriveBackupScreen> createState() =>
      _GoogleDriveBackupScreenState();
}

class _GoogleDriveBackupScreenState extends State<GoogleDriveBackupScreen> {
  bool _isLoading = true;
  bool _isSignedIn = false;
  bool _isSigningIn = false;
  bool _isSyncing = false;
  bool _autoSyncEnabled = false;
  Set<String> _downloadingIds = <String>{};
  Set<String> _deletingIds = <String>{};
  List<GoogleDriveResumeSummary> _driveResumes = const [];

  GoogleDriveResumeService get _service =>
      context.read<GoogleDriveResumeService>();

  AppPreferences get _preferences => context.read<AppPreferences>();

  @override
  void initState() {
    super.initState();
    _autoSyncEnabled = _preferences.googleDriveAutoSyncEnabled;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (!readPremiumAccess(context)) {
        Navigator.of(context).pop();
        return;
      }
      unawaited(_bootstrap());
    });
  }

  Future<void> _setAutoSyncEnabled(bool value) async {
    if (value && !readPremiumAccess(context)) {
      final allowed = await ensurePremiumForGoogleDriveBackup(context);
      if (!allowed || !mounted) {
        return;
      }
    }
    await _preferences.setGoogleDriveAutoSyncEnabled(value);
    if (!mounted) {
      return;
    }
    setState(() => _autoSyncEnabled = value);
  }

  Future<void> _bootstrap() async {
    setState(() => _isLoading = true);
    try {
      final signedIn = await _service.hasAuthorizedSession();
      final items = signedIn
          ? await _service.listResumes()
          : const <GoogleDriveResumeSummary>[];
      if (!mounted) {
        return;
      }
      setState(() {
        _isSignedIn = signedIn;
        _driveResumes = items;
      });
    } on Exception {
      if (mounted) {
        setState(() {
          _isSignedIn = false;
          _driveResumes = const [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signIn() async {
    setState(() => _isSigningIn = true);
    try {
      await _service.signIn();
      final items = await _service.listResumes();
      if (!mounted) {
        return;
      }
      setState(() {
        _isSignedIn = true;
        _driveResumes = items;
      });
    } on UnsupportedError {
      if (mounted) {
        _showMessage('Google sign-in is not available on this device.');
      }
    } on Exception {
      if (mounted) {
        _showMessage(
          'Could not sign in to Google Drive right now. Try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<void> _signOut() async {
    await _service.signOut();
    if (!mounted) {
      return;
    }
    setState(() {
      _isSignedIn = false;
      _driveResumes = const [];
    });
  }

  Future<void> _loadDriveResumes() async {
    if (!_isSignedIn) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final items = await _service.listResumes();
      if (!mounted) {
        return;
      }
      setState(() => _driveResumes = items);
    } on Exception {
      if (mounted) {
        _showMessage(
          'Could not load your Google Drive resumes right now. Try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncToDrive() async {
    final library = context.read<ResumeLibraryViewModel>();
    final repository = context.read<ResumeRepository>();
    final localResumes = library.resumes;
    if (localResumes.isEmpty) {
      _showMessage('No local resumes available to sync.');
      return;
    }

    setState(() => _isSyncing = true);
    try {
      final cloudById = {for (final item in _driveResumes) item.id: item};
      final resumesToUpload = localResumes.where((resume) {
        final cloud = cloudById[resume.id];
        return cloud == null || !cloud.updatedAt.isAfter(resume.updatedAt);
      }).toList();
      final skippedCount = localResumes.length - resumesToUpload.length;

      if (resumesToUpload.isEmpty) {
        _showMessage('All resumes are already up to date on Drive.');
        return;
      }

      final uploadedIds = await _service.uploadResumes(resumesToUpload);
      final syncedAt = DateTime.now();
      for (final resume in localResumes) {
        if (!uploadedIds.contains(resume.id)) {
          continue;
        }
        await repository.upsertResume(
          resume.copyWith(lastSyncedAt: syncedAt),
          scheduleAutoSync: false,
        );
      }

      await library.loadResumes();
      await _loadDriveResumes();

      if (!mounted) {
        return;
      }

      final uploadedCount = uploadedIds.length;
      if (skippedCount > 0) {
        _showMessage(
          'Synced $uploadedCount resumes. $skippedCount newer Drive version${skippedCount == 1 ? '' : 's'} left untouched.',
        );
      } else {
        _showMessage('Synced $uploadedCount resumes to Google Drive.');
      }
    } on Exception {
      if (mounted) {
        _showMessage(
          'Could not sync resumes to Google Drive right now. Try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _downloadResume(GoogleDriveResumeSummary item) async {
    setState(() => _downloadingIds = {..._downloadingIds, item.id});
    try {
      final repository = context.read<ResumeRepository>();
      final library = context.read<ResumeLibraryViewModel>();
      final downloaded =
          await _service.downloadResume(item.id, item.driveFileId);
      await repository.upsertResume(
        downloaded.copyWith(lastSyncedAt: DateTime.now()),
        scheduleAutoSync: false,
      );
      await library.loadResumes();
      await _loadDriveResumes();
      if (mounted) {
        _showMessage('Downloaded ${item.title}.');
      }
    } on Exception {
      if (mounted) {
        _showMessage(
          'Could not download this resume from Google Drive. Try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingIds = {..._downloadingIds}..remove(item.id));
      }
    }
  }

  Future<void> _confirmDeleteFromDrive(GoogleDriveResumeSummary item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove from Google Drive?'),
          content: Text(
            'Remove "${item.title}" from Google Drive? This will not delete the copy on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await _deleteFromDrive(item);
  }

  Future<void> _deleteFromDrive(GoogleDriveResumeSummary item) async {
    setState(() => _deletingIds = {..._deletingIds, item.id});
    try {
      await _service.deleteResume(item.driveFileId);
      await _loadDriveResumes();
      if (mounted) {
        _showMessage('Removed ${item.title} from Google Drive.');
      }
    } on Exception {
      if (mounted) {
        _showMessage(
          'Could not remove this resume from Google Drive. Try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _deletingIds = {..._deletingIds}..remove(item.id));
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showDriveResumeActions({
    required GoogleDriveResumeSummary item,
    required _DriveResumeStatus status,
  }) async {
    final canDownload = switch (status) {
      _DriveResumeStatus.driveOnly => true,
      _DriveResumeStatus.driveNewer => true,
      _DriveResumeStatus.localNewer => false,
      _DriveResumeStatus.synced => false,
    };

    final action = await showModalBottomSheet<_DriveResumeAction>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      useSafeArea: true,
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
        final primaryColor = sheetTheme.colorScheme.primary;
        final actionTextColor = sheetTheme.colorScheme.onSurface;
        final bottomInset = MediaQuery.viewPaddingOf(sheetContext).bottom;
        const disabledOpacity = 0.38;
        final disabledIconColor = primaryColor.withValues(alpha: disabledOpacity);
        final disabledTextColor = actionTextColor.withValues(
          alpha: disabledOpacity,
        );

        return Padding(
          padding: EdgeInsets.only(
            left: BottomSheetInsets.leftPadding,
            bottom: bottomInset + BottomSheetInsets.bottomSpacing,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: BottomSheetInsets.topSpacing),
              ListTile(
                leading: Icon(
                  Icons.download_rounded,
                  color: canDownload ? primaryColor : disabledIconColor,
                ),
                title: Text(
                  canDownload ? 'Download' : 'Already downloaded',
                  style: sheetTheme.textTheme.bodyLarge?.copyWith(
                    color: canDownload ? actionTextColor : disabledTextColor,
                  ),
                ),
                enabled: canDownload,
                onTap: canDownload
                    ? () => Navigator.of(
                        sheetContext,
                      ).pop(_DriveResumeAction.download)
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
                  'Remove from Google Drive',
                  style: sheetTheme.textTheme.bodyLarge?.copyWith(
                    color: actionTextColor,
                  ),
                ),
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(_DriveResumeAction.delete),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _DriveResumeAction.download:
        await _downloadResume(item);
      case _DriveResumeAction.delete:
        await _confirmDeleteFromDrive(item);
    }
  }

  Widget _buildDriveResumeCard({
    required GoogleDriveResumeSummary item,
    required _DriveResumeStatus status,
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
              : () => _showDriveResumeActions(item: item, status: status),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: _DriveResumeContent(
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
    final library = context.watch<ResumeLibraryViewModel>();
    final localById = {for (final item in library.resumes) item.id: item};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Drive backup'),
        actions: [
          if (_isSignedIn)
            TextButton(
              onPressed: _isSigningIn || _isSyncing ? null : _signOut,
              child: const Text('Sign out'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _isSignedIn ? _loadDriveResumes : _bootstrap,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  if (!_isSignedIn) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Back up resumes to a ResumeApp folder on your Google Drive. '
                              'Only files created by this app are accessible.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 14),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_box_outlined,
                                      size: 22,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'On the Google page that opens next, under '
                                        '"Select what ResumeApp can access", check the '
                                        'box next to Google Drive (files used with this '
                                        'app), then tap Continue. Without that box, '
                                        'Drive backup cannot work.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'It looks like this:',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Semantics(
                              label: 'Example Google screen: Select what ResumeApp can '
                                  'access, with the Google Drive row and checkbox.',
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.65),
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.asset(
                                  'assets/images/google_drive_permission_example.png',
                                  fit: BoxFit.fitWidth,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _isSigningIn ? null : _signIn,
                              child: _isSigningIn
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Sign in with Google'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
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
                                    if (states
                                        .contains(WidgetState.selected)) {
                                      return theme.colorScheme.onPrimary;
                                    }
                                    return theme.colorScheme.outline;
                                  }),
                                  trackColor:
                                      WidgetStateProperty.resolveWith((states) {
                                    if (states
                                        .contains(WidgetState.selected)) {
                                      return theme.colorScheme.primary;
                                    }
                                    return theme.colorScheme
                                        .surfaceContainerHighest;
                                  }),
                                  trackOutlineColor:
                                      WidgetStateProperty.resolveWith((states) {
                                    if (states
                                        .contains(WidgetState.selected)) {
                                      return Colors.transparent;
                                    }
                                    return theme.colorScheme.outlineVariant;
                                  }),
                                ),
                              ),
                              child: Switch(
                                value: _autoSyncEnabled,
                                onChanged: _isSignedIn ? _setAutoSyncEnabled : null,
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
                                  'Sync to Google Drive',
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
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  textStyle:
                                      theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                onPressed: _isSyncing ? null : _syncToDrive,
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
                    if (_driveResumes.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No resumes are stored on Drive yet.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      )
                    else ...[
                      Text(
                        'Resumes in Google Drive',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      for (final item in _driveResumes)
                        _buildDriveResumeCard(
                          item: item,
                          status: _statusFor(
                            localResume: localById[item.id],
                            driveResume: item,
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

  _DriveResumeStatus _statusFor({
    required ResumeData? localResume,
    required GoogleDriveResumeSummary driveResume,
  }) {
    if (localResume == null) {
      return _DriveResumeStatus.driveOnly;
    }
    if (driveResume.updatedAt.isAfter(localResume.updatedAt)) {
      return _DriveResumeStatus.driveNewer;
    }
    if (localResume.updatedAt.isAfter(driveResume.updatedAt)) {
      return _DriveResumeStatus.localNewer;
    }
    return _DriveResumeStatus.synced;
  }
}

enum _DriveResumeStatus { driveOnly, driveNewer, localNewer, synced }

enum _DriveResumeAction { download, delete }

class _DriveResumeContent extends StatelessWidget {
  const _DriveResumeContent({
    required this.summary,
    required this.dateFormat,
    required this.showProgress,
  });

  final GoogleDriveResumeSummary summary;
  final DateFormat dateFormat;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = summary.title.trim().isEmpty
        ? ResumeData.defaultTitle
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
        const SizedBox(width: 12),
        if (showProgress)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(
            Icons.arrow_forward_ios_rounded,
            key: Key('drive-card-arrow-${summary.id}'),
            size: 20,
            color: theme.colorScheme.primary,
          ),
      ],
    );
  }
}
