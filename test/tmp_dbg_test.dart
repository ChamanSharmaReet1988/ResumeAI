import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/resume_import_service.dart';
import 'package:resume_app/core/services/resume_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('dump candidates', () async {
    final r = ResumeData.empty(template: ResumeTemplate.softHeader).copyWith(
      fullName: 'Rohan Kapoor',
      jobTitle: 'Senior Android Developer',
      email: 'rohan.kapoor@gmail.com',
      phone: '+91 98200 11223',
      location: 'Pune, India',
      summary: 'Android developer with 7 years of experience.',
      skills: const ['Kotlin', 'Java'],
      workExperiences: const [
        WorkExperience(
          role: 'Senior Android Developer',
          company: 'PhonePe',
          startDate: 'Jan 2021',
          endDate: 'Present',
          description: '',
          bullets: ['Led the Kotlin migration of the payments module.'],
        ),
        WorkExperience(
          role: 'Android Developer',
          company: 'Flipkart',
          startDate: 'Jul 2017',
          endDate: 'Dec 2020',
          description: '',
          bullets: ['Shipped the checkout redesign.'],
        ),
      ],
      education: const [
        EducationItem(
          institution: 'College of Engineering Pune',
          degree: 'B.Tech, Computer Engineering',
          startDate: '2013',
          endDate: '2017',
          score: '',
        ),
      ],
    );
    final bytes = await ResumePdfService().buildPdf(r);
    final f = await const ResumeImportService().importPlatformFile(
      PlatformFile(name: 'a.pdf', size: bytes.length, bytes: bytes),
    );
    for (var i = 0; i < f.allResumeTexts.length; i++) {
      // ignore: avoid_print
      print('===== CANDIDATE $i =====\n${f.allResumeTexts[i]}');
    }
  });
}
