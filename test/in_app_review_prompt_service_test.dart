import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:resume_app/core/services/in_app_review_prompt_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<dynamic> box;
  var requestReviewCalls = 0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('review_prompt_test_');
    Hive.init(tempDir.path);
    final boxName =
        'review_prompt_test_${DateTime.now().microsecondsSinceEpoch}';
    box = await Hive.openBox<dynamic>(boxName);
    requestReviewCalls = 0;
  });

  tearDown(() async {
    await box.clear();
    await box.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  InAppReviewPromptService buildService() {
    return InAppReviewPromptService(
      openBox: () async => box,
      isReviewAvailable: () async => true,
      requestReview: () async {
        requestReviewCalls += 1;
      },
    );
  }

  test('prompts on first Templates visit', () async {
    final service = buildService();

    await service.handleTemplatesTabSelected();

    expect(requestReviewCalls, 1);
  });

  test('does not prompt on the next two visits', () async {
    final service = buildService();

    await service.handleTemplatesTabSelected(); // 1st → prompt
    await service.handleTemplatesTabSelected(); // 2nd
    await service.handleTemplatesTabSelected(); // 3rd

    expect(requestReviewCalls, 1);
  });

  test('prompts again on the 4th visit (3 visits after first prompt)', () async {
    final service = buildService();

    await service.handleTemplatesTabSelected(); // 1 → prompt
    await service.handleTemplatesTabSelected(); // 2
    await service.handleTemplatesTabSelected(); // 3
    await service.handleTemplatesTabSelected(); // 4 → prompt again

    expect(requestReviewCalls, 2);
  });
}
