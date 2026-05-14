import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/resume_models.dart';
import '../../core/services/app_preferences.dart';
import '../../core/services/google_drive_resume_service.dart';
import '../../core/services/resume_services.dart';
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
  List<GoogleDriveResumeSummary> _driveResumes = const [];

  GoogleDriveResumeService get _service =>
      context.read<GoogleDriveResumeService>();

  AppPreferences get _preferences => context.read<AppPreferences>();

  @override
  void initState() {
    super.initState();
    _autoSyncEnabled = _preferences.googleDriveAutoSyncEnabled;
    _bootstrap();
  }

  Future<void> _setAutoSyncEnabled(bool value) async {
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
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _isSignedIn = false;
          _driveResumes = const [];
        });
        _showMessage('Could not restore Google session: $error');
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
    } on UnsupportedError catch (error) {
      if (mounted) {
        _showMessage('$error');
      }
    } on Exception catch (error) {
      if (mounted) {
        _showMessage('Sign-in failed: $error');
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
    } on Exception catch (error) {
      if (mounted) {
        _showMessage('Could not load Drive resumes: $error');
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
    } on Exception catch (error) {
      if (mounted) {
        _showMessage('Could not sync to Drive: $error');
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
      appBar: AppBar(
        title: const Text('Google Drive Backup'),
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
                        'Resumes on Drive',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      for (final item in _driveResumes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: _DriveResumeRow(
                                summary: item,
                                status: _statusFor(
                                  localResume: localById[item.id],
                                  driveResume: item,
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

class _DriveResumeRow extends StatelessWidget {
  const _DriveResumeRow({
    required this.summary,
    required this.status,
    required this.dateFormat,
    required this.isBusy,
    required this.onDownload,
  });

  final GoogleDriveResumeSummary summary;
  final _DriveResumeStatus status;
  final DateFormat dateFormat;
  final bool isBusy;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = summary.title.trim().isEmpty
        ? ResumeData.defaultTitle
        : summary.title.trim();
    final metadataStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) - 2,
      height: 1.2,
    );

    final (buttonText, isDownloadEnabled) = switch (status) {
      _DriveResumeStatus.driveOnly => ('Download', true),
      _DriveResumeStatus.driveNewer => ('Download', true),
      _DriveResumeStatus.localNewer => ('Downloaded', false),
      _DriveResumeStatus.synced => ('Downloaded', false),
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
