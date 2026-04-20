import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/resume_models.dart';
import '../../core/services/resume_services.dart';

class SettingsViewModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void updateThemeMode(ThemeMode value) {
    if (value == _themeMode) {
      return;
    }

    _themeMode = value;
    notifyListeners();
  }
}

class ResumeLibraryViewModel extends ChangeNotifier {
  ResumeLibraryViewModel({required this.repository});

  final ResumeRepository repository;

  bool _isLoading = false;
  List<ResumeData> _resumes = const [];
  String? _selectedResumeId;
  ResumeTemplate _defaultTemplate = ResumeTemplate.corporate;

  bool get isLoading => _isLoading;
  List<ResumeData> get resumes => _resumes;
  ResumeTemplate get defaultTemplate => _defaultTemplate;
  ResumeData? get selectedResume {
    if (_selectedResumeId == null) {
      return _resumes.isEmpty ? null : _resumes.first;
    }
    for (final resume in _resumes) {
      if (resume.id == _selectedResumeId) {
        return resume;
      }
    }
    return _resumes.isEmpty ? null : _resumes.first;
  }

  Future<void> loadResumes() async {
    _isLoading = true;
    notifyListeners();
    _resumes = await repository.loadResumes();
    if (_resumes.isNotEmpty) {
      _selectedResumeId ??= _resumes.first.id;
      _defaultTemplate = _resumes.first.template.userFacingTemplate;
    }
    _isLoading = false;
    notifyListeners();
  }

  void setDefaultTemplate(ResumeTemplate template) {
    if (template == _defaultTemplate) {
      return;
    }

    _defaultTemplate = template;
    notifyListeners();
  }

  void selectResume(String id) {
    if (_selectedResumeId == id) {
      return;
    }

    _selectedResumeId = id;
    notifyListeners();
  }

  Future<void> deleteResume(String id) async {
    await repository.deleteResume(id);
    await loadResumes();
  }

  Future<ResumeData> duplicateResume(
    ResumeData source, {
    String? title,
  }) async {
    final duplicated = source.copyWith(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title == null
          ? _duplicateTitle(source.title)
          : _normalizeResumeTitle(title),
      updatedAt: DateTime.now(),
    );

    await repository.upsertResume(duplicated);
    _selectedResumeId = duplicated.id;
    await loadResumes();
    return duplicated;
  }

  Future<ResumeData> renameResume(ResumeData source, String newTitle) async {
    final renamed = source.copyWith(
      title: _normalizeResumeTitle(newTitle),
      updatedAt: DateTime.now(),
    );

    await repository.upsertResume(renamed);
    _selectedResumeId = renamed.id;
    await loadResumes();
    return renamed;
  }

  ResumeData newDraft() => ResumeData.empty(template: _defaultTemplate);

  String _duplicateTitle(String title) {
    final trimmed = title.trim();
    final baseTitle = trimmed.isEmpty ? ResumeData.defaultTitle : trimmed;
    return '$baseTitle (Copy)';
  }

  String _normalizeResumeTitle(String title) {
    final trimmed = title.trim();
    return trimmed.isEmpty ? ResumeData.defaultTitle : trimmed;
  }
}

class CoverLetterLibraryViewModel extends ChangeNotifier {
  CoverLetterLibraryViewModel({required this.repository});

  final ResumeRepository repository;

  bool _isLoading = false;
  List<CoverLetterData> _coverLetters = const [];

  bool get isLoading => _isLoading;
  List<CoverLetterData> get coverLetters => _coverLetters;

  Future<void> loadCoverLetters() async {
    _isLoading = true;
    notifyListeners();
    _coverLetters = await repository.loadCoverLetters();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteCoverLetter(String id) async {
    await repository.deleteCoverLetter(id);
    await loadCoverLetters();
  }

  CoverLetterData newDraft() => CoverLetterData.empty();
}

class ResumeEditorViewModel extends ChangeNotifier {
  static const int maxSkills = 50;
  static const Duration _autoSaveDelay = Duration(milliseconds: 500);

  ResumeEditorViewModel({
    required this.repository,
    required this.aiService,
    required this.pdfService,
    required ResumeData seedResume,
  }) : _resume = seedResume;

  final ResumeRepository repository;
  final LocalAiResumeService aiService;
  final ResumePdfService pdfService;

  ResumeData _resume;
  int _currentStep = 0;
  bool _isBusy = false;
  ResumeAnalysis? _analysis;
  JobDescriptionInsights? _jobInsights;
  String _coverLetter = '';
  Timer? _autoSaveTimer;
  Future<void> _autoSaveInFlight = Future<void>.value();
  bool _hasAutoSaveInFlight = false;

  ResumeData get resume => _resume;
  int get currentStep => _currentStep;
  bool get isBusy => _isBusy;
  ResumeAnalysis? get analysis => _analysis;
  JobDescriptionInsights? get jobInsights => _jobInsights;
  String get coverLetter => _coverLetter;
  bool get hasReachedSkillLimit => _resume.skills.length >= maxSkills;

  /// Fixed builder steps (horizontal chips before user-defined categories).
  static const coreStepTitles = [
    'Personal Information',
    'Work Experience',
    'Education',
    'Skills',
    'Projects',
  ];

  static const int coreStepCount = 5;

  /// Total swipeable steps: core + one page per [ResumeData.customSections] entry.
  int get totalStepCount => coreStepCount + _resume.customSections.length;

  void setStep(int value) {
    final maxStep = totalStepCount - 1;
    if (maxStep < 0) {
      return;
    }
    _currentStep = value.clamp(0, maxStep);
    if (_currentStep == maxStep) {
      analyzeResume();
    } else {
      notifyListeners();
    }
  }

  void nextStep() {
    setStep(_currentStep + 1);
  }

  void previousStep() {
    setStep(_currentStep - 1);
  }

  void updateResume(ResumeData Function(ResumeData current) update) {
    _resume = update(_resume).copyWith(updatedAt: DateTime.now());
    notifyListeners();
    _scheduleAutoSave();
  }

  void updateWorkExperience(
    int index,
    WorkExperience Function(WorkExperience current) update,
  ) {
    final items = [..._resume.workExperiences];
    items[index] = update(items[index]);
    updateResume((resume) => resume.copyWith(workExperiences: items));
  }

  void addWorkExperience() {
    updateResume(
      (resume) => resume.copyWith(
        workExperiences: [
          ...resume.workExperiences,
          const WorkExperience.empty(),
        ],
      ),
    );
  }

  void removeWorkExperience(int index) {
    final items = [..._resume.workExperiences]..removeAt(index);
    updateResume(
      (resume) => resume.copyWith(
        workExperiences: items.isEmpty ? const [WorkExperience.empty()] : items,
      ),
    );
  }

  void moveWorkExperienceUp(int index) {
    if (index <= 0 || index >= _resume.workExperiences.length) {
      return;
    }

    final items = [..._resume.workExperiences];
    final item = items.removeAt(index);
    items.insert(index - 1, item);
    updateResume((resume) => resume.copyWith(workExperiences: items));
  }

  void moveWorkExperienceDown(int index) {
    if (index < 0 || index >= _resume.workExperiences.length - 1) {
      return;
    }

    final items = [..._resume.workExperiences];
    final item = items.removeAt(index);
    items.insert(index + 1, item);
    updateResume((resume) => resume.copyWith(workExperiences: items));
  }

  void updateEducation(
    int index,
    EducationItem Function(EducationItem current) update,
  ) {
    final items = [..._resume.education];
    items[index] = update(items[index]);
    updateResume((resume) => resume.copyWith(education: items));
  }

  void addEducation() {
    updateResume(
      (resume) => resume.copyWith(
        education: [...resume.education, const EducationItem.empty()],
      ),
    );
  }

  void removeEducation(int index) {
    final items = [..._resume.education]..removeAt(index);
    updateResume(
      (resume) => resume.copyWith(
        education: items.isEmpty ? const [EducationItem.empty()] : items,
      ),
    );
  }

  void moveEducationUp(int index) {
    if (index <= 0 || index >= _resume.education.length) {
      return;
    }

    final items = [..._resume.education];
    final item = items.removeAt(index);
    items.insert(index - 1, item);
    updateResume((resume) => resume.copyWith(education: items));
  }

  void moveEducationDown(int index) {
    if (index < 0 || index >= _resume.education.length - 1) {
      return;
    }

    final items = [..._resume.education];
    final item = items.removeAt(index);
    items.insert(index + 1, item);
    updateResume((resume) => resume.copyWith(education: items));
  }

  void updateProject(
    int index,
    ProjectItem Function(ProjectItem current) update,
  ) {
    final items = [..._resume.projects];
    items[index] = update(items[index]);
    updateResume((resume) => resume.copyWith(projects: items));
  }

  void addProject() {
    updateResume(
      (resume) => resume.copyWith(
        projects: [...resume.projects, const ProjectItem.empty()],
      ),
    );
  }

  void removeProject(int index) {
    final items = [..._resume.projects]..removeAt(index);
    updateResume(
      (resume) => resume.copyWith(
        projects: items.isEmpty ? const [ProjectItem.empty()] : items,
      ),
    );
  }

  void moveProjectUp(int index) {
    if (index <= 0 || index >= _resume.projects.length) {
      return;
    }

    final items = [..._resume.projects];
    final item = items.removeAt(index);
    items.insert(index - 1, item);
    updateResume((resume) => resume.copyWith(projects: items));
  }

  void moveProjectDown(int index) {
    if (index < 0 || index >= _resume.projects.length - 1) {
      return;
    }

    final items = [..._resume.projects];
    final item = items.removeAt(index);
    items.insert(index + 1, item);
    updateResume((resume) => resume.copyWith(projects: items));
  }

  void updateCustomSection(
    int index,
    CustomSectionItem Function(CustomSectionItem current) update,
  ) {
    final items = [..._resume.customSections];
    items[index] = update(items[index]);
    updateResume((resume) => resume.copyWith(customSections: items));
  }

  void addCustomSection() {
    addCustomSectionWithTitle('');
  }

  void addCustomSectionWithTitle(String title) {
    final trimmed = title.trim();
    updateResume(
      (resume) => resume.copyWith(
        customSections: [
          ...resume.customSections,
          CustomSectionItem(title: trimmed, content: ''),
        ],
      ),
    );
  }

  void removeCustomSection(int index) {
    final items = [..._resume.customSections]..removeAt(index);
    final newCount = items.length;
    _currentStep = _currentStep.clamp(0, coreStepCount + newCount - 1);
    updateResume((resume) => resume.copyWith(customSections: items));
  }

  void setIncludeWorkInResume(bool value) {
    updateResume((resume) => resume.copyWith(includeWorkInResume: value));
  }

  void setIncludeEducationInResume(bool value) {
    updateResume((resume) => resume.copyWith(includeEducationInResume: value));
  }

  void setIncludeSkillsInResume(bool value) {
    updateResume((resume) => resume.copyWith(includeSkillsInResume: value));
  }

  void setIncludeProjectsInResume(bool value) {
    updateResume((resume) => resume.copyWith(includeProjectsInResume: value));
  }

  void moveCustomSectionUp(int index) {
    if (index <= 0 || index >= _resume.customSections.length) {
      return;
    }

    final items = [..._resume.customSections];
    final item = items.removeAt(index);
    items.insert(index - 1, item);
    updateResume((resume) => resume.copyWith(customSections: items));
  }

  void moveCustomSectionDown(int index) {
    if (index < 0 || index >= _resume.customSections.length - 1) {
      return;
    }

    final items = [..._resume.customSections];
    final item = items.removeAt(index);
    items.insert(index + 1, item);
    updateResume((resume) => resume.copyWith(customSections: items));
  }

  bool addSkill(String skill) {
    final value = skill.trim();
    if (value.isEmpty) {
      return false;
    }

    if (_resume.skills.contains(value) || hasReachedSkillLimit) {
      return false;
    }

    final items = {..._resume.skills, value}.toList()..sort();
    updateResume((resume) => resume.copyWith(skills: items));
    return true;
  }

  void removeSkill(String skill) {
    final items = [..._resume.skills]..remove(skill);
    updateResume((resume) => resume.copyWith(skills: items));
  }

  Future<void> generateSummary() async {
    await _runBusy(() async {
      final summary = await aiService.generateSummary(_resume);
      updateResume((resume) => resume.copyWith(summary: summary));
    });
  }

  Future<void> generateBullets(int index) async {
    if (index < 0 || index >= _resume.workExperiences.length) {
      return;
    }

    await _runBusy(() async {
      final experience = _resume.workExperiences[index];
      final bullets = await aiService.generateJobBullets(
        role: experience.role,
        company: experience.company,
        targetJobTitle: _resume.jobTitle,
      );
      if (index < 0 || index >= _resume.workExperiences.length) {
        return;
      }
      if (bullets.isEmpty) {
        return;
      }

      updateWorkExperience(
        index,
        (current) => current.copyWith(
          bullets: {...current.bullets, ...bullets}.toList(),
        ),
      );
    });
  }

  Future<void> suggestSkills() async {
    await _runBusy(() async {
      final suggestions = await aiService.suggestSkills(resume: _resume);
      final items = {..._resume.skills, ...suggestions}.toList()..sort();
      updateResume(
        (resume) => resume.copyWith(skills: items.take(maxSkills).toList()),
      );
    });
  }

  Future<void> improveResume() async {
    await _runBusy(() async {
      final suggestions = await aiService.improveResume(_resume);
      _analysis = ResumeAnalysis(
        score: _analysis?.score ?? (_resume.completionRatio * 100).round(),
        atsCompatibility:
            _analysis?.atsCompatibility ?? _resume.completionRatio,
        missingSkills: _analysis?.missingSkills ?? const [],
        weakDescriptions: _analysis?.weakDescriptions ?? const [],
        strengths: _analysis?.strengths ?? const [],
        improvements: suggestions,
      );
      notifyListeners();
    });
  }

  Future<void> analyzeResume({String jobDescription = ''}) async {
    await _runBusy(() async {
      _analysis = await aiService.analyzeResume(
        resume: _resume,
        jobDescription: jobDescription,
      );
      notifyListeners();
    }, notifyOnExit: false);
    notifyListeners();
  }

  Future<void> analyzeJobDescription(String jobDescription) async {
    await _runBusy(() async {
      _jobInsights = await aiService.analyzeJobDescription(
        jobDescription: jobDescription,
        resume: _resume,
      );
      notifyListeners();
    }, notifyOnExit: false);
    notifyListeners();
  }

  Future<void> generateCoverLetter({
    required String company,
    required String role,
  }) async {
    await _runBusy(() async {
      _coverLetter = await aiService.generateCoverLetter(
        resume: _resume,
        company: company,
        role: role,
      );
      notifyListeners();
    }, notifyOnExit: false);
    notifyListeners();
  }

  void oneClickGenerate() {
    final fallbackTitle = _resume.jobTitle.trim().isEmpty
        ? 'Product Designer'
        : _resume.jobTitle;
    final summary = _resume.summary.trim().isEmpty
        ? 'Impact-oriented $fallbackTitle with a strong bias for shipping polished work quickly, collaborating across teams, and turning ambiguous goals into structured results.'
        : _resume.summary;

    final skills = _resume.skills.isEmpty
        ? {
            'Communication',
            'Problem Solving',
            'Stakeholder Management',
            ..._suggestOfflineSkills(fallbackTitle),
          }.toList()
        : _resume.skills;

    final workExperiences = _resume.visibleWorkExperiences.isEmpty
        ? [
            WorkExperience(
              role: fallbackTitle,
              company: 'Growth Studio',
              startDate: '2023',
              endDate: 'Present',
              description:
                  'Owned fast-turn project delivery and improved team workflows for better quality and speed.',
              bullets: [
                'Delivered user-facing improvements from brief to launch with clear stakeholder alignment and rapid iteration.',
                'Built reusable systems and templates that reduced handoff friction and improved delivery consistency.',
                'Used feedback loops and lightweight analysis to prioritize the highest-impact changes first.',
              ],
              layoutMode: WorkExperienceLayoutMode.bullets,
            ),
          ]
        : _resume.workExperiences;

    final education = _resume.visibleEducation.isEmpty
        ? [
            const EducationItem(
              institution: 'Your University',
              degree: 'Bachelor of Technology',
              year: '2022',
              score: '8.5 CGPA',
              details: 'Relevant coursework, achievements, or specialization',
            ),
          ]
        : _resume.education;

    final projects = _resume.visibleProjects.isEmpty
        ? [
            const ProjectItem(
              title: 'AI Resume Builder',
              subtitle: '',
              overview:
                  'Built a mobile app that lets users create polished resumes in minutes with guided prompts and AI suggestions.',
              impact: 'Flutter, Dart, Material 3',
            ),
          ]
        : _resume.projects;

    updateResume(
      (resume) => resume.copyWith(
        summary: summary,
        skills: skills,
        workExperiences: workExperiences,
        education: education,
        projects: projects,
        title: resume.jobTitle.trim().isEmpty
            ? 'Professional Resume'
            : '${resume.jobTitle.trim()} Resume',
      ),
    );
  }

  Future<void> saveResume() async {
    _autoSaveTimer?.cancel();
    if (_hasAutoSaveInFlight) {
      try {
        await _autoSaveInFlight;
      } catch (_) {}
    }

    await _runBusy(() async {
      final normalizedTitle = _normalizeResumeTitle(_resume.title);

      final normalizedResume = _resume.copyWith(
        title: normalizedTitle,
        updatedAt: DateTime.now(),
      );
      _resume = normalizedResume;
      await repository.upsertResume(normalizedResume);
    });
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      final draftResume = _resume.copyWith(
        title: _normalizeResumeTitle(_resume.title),
        updatedAt: DateTime.now(),
      );
      _hasAutoSaveInFlight = true;
      _autoSaveInFlight = repository.upsertResume(draftResume).whenComplete(() {
        _hasAutoSaveInFlight = false;
      });
      unawaited(_autoSaveInFlight);
    });
  }

  String _normalizeResumeTitle(String title) {
    final trimmed = title.trim();
    return trimmed.isEmpty ? ResumeData.defaultTitle : trimmed;
  }

  Future<String> downloadPdf() async {
    String savedPath = '';
    await _runBusy(() async {
      final file = await pdfService.savePdfToDevice(_resume);
      savedPath = file.path;
    });
    return savedPath;
  }

  Future<void> sharePdf() async {
    await _runBusy(() => pdfService.shareResume(_resume));
  }

  Future<void> printPdf() async {
    await _runBusy(() => pdfService.printResume(_resume));
  }

  List<String> _suggestOfflineSkills(String jobTitle) {
    final normalized = jobTitle.toLowerCase();
    if (normalized.contains('design')) {
      return ['Figma', 'Prototyping', 'Design Systems'];
    }
    if (normalized.contains('engineer') || normalized.contains('developer')) {
      return ['Flutter', 'Dart', 'REST APIs'];
    }
    if (normalized.contains('product')) {
      return ['Roadmapping', 'Analytics', 'A/B Testing'];
    }
    return ['Project Management', 'Documentation', 'Execution'];
  }

  Future<void> _runBusy(
    Future<void> Function() action, {
    bool notifyOnExit = true,
  }) async {
    _isBusy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _isBusy = false;
      if (notifyOnExit) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}

class CoverLetterEditorViewModel extends ChangeNotifier {
  CoverLetterEditorViewModel({
    required this.repository,
    required this.aiService,
    required this.resumeContext,
    required CoverLetterData seedCoverLetter,
  }) : _coverLetter = seedCoverLetter;

  final ResumeRepository repository;
  final LocalAiResumeService aiService;
  final ResumeData? resumeContext;

  CoverLetterData _coverLetter;
  bool _isBusy = false;

  CoverLetterData get coverLetter => _coverLetter;
  bool get isBusy => _isBusy;

  void updateCoverLetter(
    CoverLetterData Function(CoverLetterData current) update,
  ) {
    _coverLetter = update(_coverLetter).copyWith(updatedAt: DateTime.now());
    notifyListeners();
  }

  bool get canCreateCoverLetter =>
      _coverLetter.company.trim().isNotEmpty &&
      _coverLetter.role.trim().isNotEmpty;

  Future<void> createCoverLetter() async {
    if (!canCreateCoverLetter) {
      return;
    }

    _isBusy = true;
    notifyListeners();

    try {
      final normalized = _coverLetter.copyWith(
        company: _coverLetter.company.trim(),
        role: _coverLetter.role.trim(),
        skillToHighlight: _coverLetter.skillToHighlight.trim(),
        language: _coverLetter.language.trim(),
        content: _coverLetter.content.trim(),
        updatedAt: DateTime.now(),
      );

      final resume =
          resumeContext ?? ResumeData.empty(template: ResumeTemplate.corporate);
      final generatedContent = await aiService.generateCoverLetter(
        resume: resume,
        company: normalized.company,
        role: normalized.role,
        skillToHighlight: normalized.skillToHighlight,
        language: normalized.language,
      );

      _coverLetter = normalized.copyWith(
        title: normalized.title.trim().isNotEmpty
            ? normalized.title.trim()
            : '${normalized.role} · ${normalized.company}',
        content: generatedContent,
        updatedAt: DateTime.now(),
      );

      await repository.upsertCoverLetter(_coverLetter);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> saveCoverLetter({bool showBusy = true}) async {
    if (showBusy) {
      _isBusy = true;
      notifyListeners();
    }

    try {
      final normalized = _coverLetter.copyWith(
        title: _coverLetter.title.trim(),
        company: _coverLetter.company.trim(),
        role: _coverLetter.role.trim(),
        skillToHighlight: _coverLetter.skillToHighlight.trim(),
        language: _coverLetter.language.trim(),
        content: _coverLetter.content.trim(),
        updatedAt: DateTime.now(),
      );

      _coverLetter = normalized;
      await repository.upsertCoverLetter(normalized);
    } finally {
      if (showBusy) {
        _isBusy = false;
        notifyListeners();
      }
    }
  }
}
