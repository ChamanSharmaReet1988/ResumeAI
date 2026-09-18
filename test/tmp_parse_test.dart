import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/models/resume_models.dart';
import 'package:resume_app/core/services/resume_services.dart';

const _text = '''
ROHAN KAPOOR
Senior Android Developer
PROFILE SUMMARY
Android developer with 7 years of experience.
WORK EXPERIENCE
PhonePe
JAN 2021 - PRESENT
Senior Android Developer
Led the Kotlin migration of the payments module.
Flipkart | JUL 2017 - DEC 2020
Android Developer
Shipped the checkout redesign.
CONTACT
+91 98200 11223
rohan.kapoor@gmail.com
Pune, India
EDUCATION
2013 - 2017
COLLEGE OF ENGINEERING PUNE
B.Tech, Computer Engineering
SKILLS
Kotlin
Java
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('parse split text', () {
    final parsed = LocalAiResumeService().parseImportedResumeText(
      resumeText: _text,
      template: ResumeTemplate.corporate,
      sourceTitle: 'r',
    );
    // ignore: avoid_print
    print(
      'name=${parsed.fullName}\ntitle=${parsed.jobTitle}\nemail=${parsed.email}\n'
      'phone=${parsed.phone}\nlocation=${parsed.location}\n'
      'summary=${parsed.summary}\nskills=${parsed.skills}\n'
      'edu=${parsed.visibleEducation.map((e) => '${e.institution} | ${e.degree} | ${e.startDate}-${e.endDate}').toList()}\n'
      'jobs=${parsed.visibleWorkExperiences.map((w) => '${w.role} @ ${w.company} (${w.startDate}-${w.endDate}) ${w.bullets}').toList()}',
    );
  });
}
