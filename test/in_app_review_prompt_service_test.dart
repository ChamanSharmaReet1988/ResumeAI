import 'package:flutter_test/flutter_test.dart';

import 'package:resume_app/core/services/in_app_review_prompt_service.dart';

void main() {
  late bool ratingCompleted;
  late int openStoreListingCalls;
  late int requestNativeReviewCalls;

  InAppReviewPromptService buildService() {
    return InAppReviewPromptService(
      readRatingCompleted: () async => ratingCompleted,
      writeRatingCompleted: () async {
        ratingCompleted = true;
      },
      openStoreListing: () async {
        openStoreListingCalls += 1;
      },
      requestNativeReview: () async {
        requestNativeReviewCalls += 1;
      },
    );
  }

  setUp(() {
    ratingCompleted = false;
    openStoreListingCalls = 0;
    requestNativeReviewCalls = 0;
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

  test('does not claim while a prompt is in flight', () async {
    final service = buildService();

    expect(await service.claimHomePrompt(resumeCount: 1), isTrue);
    expect(await service.claimHomePrompt(resumeCount: 1), isFalse);
  });

  test('claims again after deferral is cleared by next home visit', () async {
    final service = buildService();

    expect(await service.claimHomePrompt(resumeCount: 1), isTrue);
    service.deferUntilNextHomeVisit();
    service.endPromptOffer();
    expect(await service.claimHomePrompt(resumeCount: 1), isFalse);

    service.onArrivedAtHome();
    expect(await service.claimHomePrompt(resumeCount: 1), isTrue);
  });

  test('does not claim after the user has rated', () async {
    ratingCompleted = true;
    final service = buildService();

    expect(await service.claimHomePrompt(resumeCount: 1), isFalse);
  });

  test('requestNativeReview uses the injected requester', () async {
    final service = buildService();
    await service.requestNativeReview();
    expect(requestNativeReviewCalls, 1);
  });

  test('openStoreListing uses the injected opener', () async {
    final service = buildService();
    await service.openStoreListing();
    expect(openStoreListingCalls, 1);
  });
}
