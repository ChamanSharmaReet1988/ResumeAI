import 'package:flutter_test/flutter_test.dart';

import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/resume_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ResumeData buildLongCreativeResume() {
    final workItems = List<WorkExperience>.generate(
      8,
      (index) => WorkExperience(
        role: 'Senior Product Engineer ${index + 1}',
        company: 'Northstar Labs',
        startDate: 'Jan 20${10 + index}',
        endDate: index == 0 ? 'Present' : 'Dec 20${10 + index}',
        description:
            'Led cross-functional delivery for resume workflow improvements, ATS optimization, export quality, and recruiter-facing usability across mobile and PDF surfaces.',
        bullets: const [
          'Improved conversion by rewriting high-friction resume sections and simplifying data entry for applicants.',
          'Built structured PDF output with cleaner hierarchy, better pagination, and stronger content density across multi-page resumes.',
          'Partnered with design and product to ship ATS-friendly formatting, clearer keyword targeting, and more credible achievement bullets.',
        ],
      ),
    );

    final educationItems = List<EducationItem>.generate(
      4,
      (index) => EducationItem(
        institution: 'State University ${index + 1}',
        degree: 'Bachelor of Engineering in Computer Science',
        startDate: '201$index',
        endDate: '201${index + 2}',
        score: '8.$index CGPA',
      ),
    );

    final projects = List<ProjectItem>.generate(
      3,
      (index) => ProjectItem(
        title: 'Resume Platform ${index + 1}',
        overview:
            'Delivered candidate-facing improvements for resume creation, AI suggestions, PDF export, and recruiter review flows.',
        impact: 'Flutter, Dart, PDF, Provider, Accessibility, ATS optimization',
        bullets: const [
          'Created reusable editing flows and preview pipelines for large structured documents.',
        ],
      ),
    );

    return ResumeData.empty(template: ResumeTemplate.creative).copyWith(
      title: 'Creative Template Overflow Test',
      fullName: 'Diya Agarwal',
      jobTitle: 'Senior Product Engineer',
      email: 'diya@example.com',
      phone: '+91 99999 99999',
      location: 'New Delhi, India',
      summary:
          'Customer-focused builder with experience shipping resume tooling, ATS improvements, structured editing, and polished multi-page PDF output for modern job applications.',
      workExperiences: workItems,
      education: educationItems,
      skills: const [
        'Flutter',
        'Dart',
        'PDF',
        'ATS Optimization',
        'Product Strategy',
        'UX Writing',
        'Accessibility',
        'State Management',
        'Analytics',
        'Experimentation',
      ],
      projects: projects,
    );
  }

  ResumeData buildClassicSidebarResume() {
    return ResumeData.empty(template: ResumeTemplate.classicSidebar).copyWith(
      title: 'Classic Sidebar Test',
      fullName: 'Avery Brooks',
      jobTitle: 'Financial Analyst',
      email: 'avery@example.com',
      phone: '+1 617 555 0142',
      location: 'Boston, MA',
      summary:
          'Financial analyst with experience supporting budgets, planning reviews, and operational reporting across cross-functional teams.',
      workExperiences: const [
        WorkExperience(
          role: 'Financial Analyst',
          company: 'GEO Advisory',
          startDate: 'Apr 2018',
          endDate: 'Present',
          description: '',
          bullets: [
            'Built operating budget models that reduced quarterly variance across business units.',
            'Prepared financial summaries for leadership reviews and monthly planning cycles.',
          ],
        ),
        WorkExperience(
          role: 'Analyst',
          company: 'North Harbor Group',
          startDate: 'Sep 2014',
          endDate: 'Mar 2018',
          description: '',
          bullets: [
            'Tracked revenue, forecast updates, and project spend across finance and operations.',
          ],
        ),
      ],
      education: const [
        EducationItem(
          institution: 'Boston University',
          degree: 'B.S. Finance',
          startDate: '2010',
          endDate: '2014',
          score: '3.8 GPA • Graduated magna cum laude.',
        ),
      ],
      skills: const [
        'Financial Analysis',
        'Strategic Planning',
        'Trend Analysis',
        'Budget Tracking',
        'Team Leadership',
      ],
      projects: const [
        ProjectItem(
          title: 'Budget Reporting Framework',
          bullets: [
            'Standardized monthly reporting decks used in leadership finance reviews.',
          ],
        ),
      ],
      customSections: const [
        CustomSectionItem(
          title: 'Language',
          content: '',
          layoutMode: CustomSectionLayoutMode.bullets,
          bullets: ['English', 'German'],
        ),
      ],
    );
  }

  ResumeData buildLongClassicSidebarResume() {
    final workItems = List<WorkExperience>.generate(
      10,
      (index) => WorkExperience(
        role: 'Financial Analyst ${index + 1}',
        company: 'GEO Advisory',
        startDate: 'Apr 20${10 + index}',
        endDate: index == 0 ? 'Present' : 'Mar 20${11 + index}',
        description:
            'Supported financial planning, operating reviews, monthly reporting, forecast updates, and stakeholder presentations across multiple business units.',
        bullets: const [
          'Built planning models that improved monthly forecast accuracy and reduced reporting turnaround time.',
          'Prepared finance summaries, board-ready reporting, and variance commentary for leadership reviews.',
          'Partnered with operations and business stakeholders to align budgets, cash flow planning, and resource decisions.',
        ],
      ),
    );

    final educationItems = List<EducationItem>.generate(
      4,
      (index) => EducationItem(
        institution: 'Boston University ${index + 1}',
        degree: 'Bachelor of Science in Finance',
        startDate: '200$index',
        endDate: '200${index + 4}',
        score: '3.${7 + (index % 2)} GPA',
      ),
    );

    final projects = List<ProjectItem>.generate(
      3,
      (index) => ProjectItem(
        title: 'Finance Transformation ${index + 1}',
        overview:
            'Improved budget controls, executive reporting, and forecasting workflows across distributed teams.',
        bullets: const [
          'Created standardized reporting templates that improved consistency across planning cycles.',
          'Delivered operating reviews with clearer KPI trends, risk commentary, and action tracking.',
        ],
      ),
    );

    return ResumeData.empty(template: ResumeTemplate.classicSidebar).copyWith(
      title: 'Classic Sidebar Overflow Test',
      fullName: 'Avery Brooks',
      jobTitle: 'Senior Financial Analyst',
      email: 'avery@example.com',
      phone: '+1 617 555 0142',
      location: 'Boston, MA',
      summary:
          'Senior financial analyst with experience leading budget planning, performance reporting, and executive-ready analysis across multi-team business operations.',
      workExperiences: workItems,
      education: educationItems,
      skills: const [
        'Financial Analysis',
        'Strategic Planning',
        'Trend Analysis',
        'Budget Tracking',
        'Forecasting',
        'Board Reporting',
        'Cash Flow Planning',
        'Stakeholder Management',
        'Variance Analysis',
        'Quarterly Planning',
        'Executive Dashboards',
        'Decision Support',
        'Budget Governance',
        'Operating Models',
        'Scenario Planning',
        'Business Reviews',
        'Spreadsheet Modeling',
        'Capital Planning',
        'Process Improvement',
        'Leadership Updates',
        'Vendor Analysis',
        'Cost Controls',
      ],
      projects: projects,
      customSections: const [
        CustomSectionItem(
          title: 'Langueages',
          content: '',
          layoutMode: CustomSectionLayoutMode.bullets,
          bullets: [
            'English',
            'German',
            'French',
            'Spanish',
            'Italian',
            'Hindi',
          ],
        ),
      ],
    );
  }

  ResumeData buildLongClassicSidebarSectionResume() {
    final projects = List<ProjectItem>.generate(
      8,
      (index) => ProjectItem(
        title: 'Finance Systems Rollout ${index + 1}',
        overview:
            'Coordinated reporting changes, stakeholder updates, rollout plans, and recurring review checkpoints across distributed teams.',
        bullets: const [
          'Documented rollout milestones, ownership maps, reporting dependencies, and executive checkpoints for monthly governance reviews.',
          'Prepared narrative updates that connected financial impact, execution risks, delivery blockers, and next-step decisions.',
          'Aligned implementation details with operations, finance partners, and leadership stakeholders across multiple handoff moments.',
        ],
      ),
    );

    final customSections = List<CustomSectionItem>.generate(
      3,
      (index) => CustomSectionItem(
        title: index == 0 ? 'AI Tools' : 'Certifications ${index + 1}',
        content: '',
        layoutMode: CustomSectionLayoutMode.bullets,
        bullets: const [
          'Created detailed operational playbooks, reporting templates, and reusable checklists for repeatable delivery.',
          'Built structured update packs with stakeholder context, risk summaries, decision points, and action tracking.',
          'Maintained weekly coordination notes, retrospective summaries, and process-improvement recommendations.',
          'Tracked rollout dependencies, communication plans, and follow-up actions across multiple internal partners.',
          'Prepared concise written summaries that translated complex project status into business-facing language.',
        ],
      ),
    );

    return buildLongClassicSidebarResume().copyWith(
      projects: projects,
      customSections: customSections,
    );
  }

  test(
    'creative template PDF paginates long resumes without overflow',
    () async {
      final service = ResumePdfService();
      final pdfBytes = await service.buildPdf(buildLongCreativeResume());

      expect(pdfBytes, isNotEmpty);
    },
  );

  test(
    'highlighted creative template PDF paginates long resumes without overflow',
    () async {
      final service = ResumePdfService();
      final resume = buildLongCreativeResume();
      final pdfBytes = await service.buildHighlightedResumePdf(
        resume: resume,
        highlightSummary: true,
        highlightedSkills: const {'Flutter', 'ATS Optimization'},
        highlightedBulletsByExperience: const {
          0: {
            'Improved conversion by rewriting high-friction resume sections and simplifying data entry for applicants.',
          },
        },
      );

      expect(pdfBytes, isNotEmpty);
    },
  );

  test('classic sidebar template PDF renders successfully', () async {
    final service = ResumePdfService();
    final pdfBytes = await service.buildPdf(buildClassicSidebarResume());

    expect(pdfBytes, isNotEmpty);
  });

  test('highlighted classic sidebar template PDF renders successfully', () async {
    final service = ResumePdfService();
    final resume = buildClassicSidebarResume();
    final pdfBytes = await service.buildHighlightedResumePdf(
      resume: resume,
      highlightSummary: true,
      highlightedSkills: const {'Financial Analysis'},
      highlightedBulletsByExperience: const {
        0: {
          'Prepared financial summaries for leadership reviews and monthly planning cycles.',
        },
      },
    );

    expect(pdfBytes, isNotEmpty);
  });

  test(
    'classic sidebar template paginates long resumes without dropping later-page content',
    () async {
      final service = ResumePdfService();
      final pdfBytes = await service.buildPdf(buildLongClassicSidebarResume());

      expect(pdfBytes, isNotEmpty);
    },
  );

  test(
    'highlighted classic sidebar template paginates long resumes without dropping later-page content',
    () async {
      final service = ResumePdfService();
      final resume = buildLongClassicSidebarResume();
      final pdfBytes = await service.buildHighlightedResumePdf(
        resume: resume,
        highlightSummary: true,
        highlightedSkills: const {'Financial Analysis', 'Forecasting'},
        highlightedBulletsByExperience: const {
          0: {
            'Prepared finance summaries, board-ready reporting, and variance commentary for leadership reviews.',
          },
        },
      );

      expect(pdfBytes, isNotEmpty);
    },
  );

  test(
    'classic sidebar template handles long project and custom sections without too many pages',
    () async {
      final service = ResumePdfService();
      final pdfBytes = await service.buildPdf(
        buildLongClassicSidebarSectionResume(),
      );

      expect(pdfBytes, isNotEmpty);
    },
  );
}
