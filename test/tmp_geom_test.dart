import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/resume_services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('geometry', () async {
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
    final doc = sf.PdfDocument(inputBytes: bytes);
    final lines = sf.PdfTextExtractor(doc).extractTextLines();
    final width = doc.pages[0].size.width;
    // ignore: avoid_print
    print('pageWidth=$width lines=${lines.length}');
    for (final line in lines.take(40)) {
      // ignore: avoid_print
      print(
        '${line.bounds.left.toStringAsFixed(0)}-${line.bounds.right.toStringAsFixed(0)}'
        '  ${line.text.trim()}',
      );
    }
    doc.dispose();
  });
}
