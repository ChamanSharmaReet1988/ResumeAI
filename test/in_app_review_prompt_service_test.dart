import 'package:flutter_test/flutter_test.dart';

import 'package:resume_app/core/services/in_app_review_prompt_service.dart';

void main() {
  late bool ratingCompleted;
  late int openStoreListingCalls;

  InAppReviewPromptService buildService() {
    return InAppReviewPromptService(
      readRatingCompleted: () async => ratingCompleted,
      writeRatingCompleted: () async {
        ratingCompleted = true;
      },
      openStoreListing: () async {
        openStoreListingCalls += 1;
      },
    );
  }

  setUp(() {
    ratingCompleted = false;
    openStoreListingCalls = 0;
  });

  test('claims prompt when home has exactly one resume', () async {
    final service = buildService();

    expect(await service.claimHomePrompt(resumeCount: 1), isTrue);
  });

  test('does not claim when there are no resumes', () async {
    final service = buildService();

    expect(await service.claimHomePrompt(resumeCount: 0), isFalse);
  });

  test('does not claim when there are two resumes', () async {
    final service = buildService();

    expect(await service.claimHomePrompt(resumeCount: 2), isFalse);
  });

  test('does not claim twice in the same session', () async {
    final service = buildService();

    expect(await service.claimHomePrompt(resumeCount: 1), isTrue);
    service.endPromptOffer();
    expect(await service.claimHomePrompt(resumeCount: 1), isFalse);
  });

  test('does not claim after the user has rated', () async {
    ratingCompleted = true;
    final service = buildService();

    expect(await service.claimHomePrompt(resumeCount: 1), isFalse);
  });

  test('rating flag survives a new service instance after reinstall', () async {
    final firstLaunch = buildService();
    expect(await firstLaunch.claimHomePrompt(resumeCount: 1), isTrue);
    await firstLaunch.markRatingCompleted();
    firstLaunch.endPromptOffer();

    final afterReinstall = buildService();
    expect(await afterReinstall.hasCompletedRating(), isTrue);
    expect(await afterReinstall.claimHomePrompt(resumeCount: 1), isFalse);
  });

  test('openStoreListing uses the injected opener', () async {
    final service = buildService();
    await service.openStoreListing();
    expect(openStoreListingCalls, 1);
  });
}
