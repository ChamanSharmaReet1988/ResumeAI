import 'package:flutter_test/flutter_test.dart';

import 'package:resume_app/core/services/in_app_review_prompt_service.dart';

void main() {
  late bool ratingCompleted;
  late int openStoreListingCalls;
  late int requestNativeReviewCalls;
  late int homeVisitCount;

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
      readHomeVisitCount: () async => homeVisitCount,
      writeHomeVisitCount: (count) async {
        homeVisitCount = count;
      },
    );
  }

  setUp(() {
    ratingCompleted = false;
    openStoreListingCalls = 0;
    requestNativeReviewCalls = 0;
    homeVisitCount = 0;
  });

  test('does not claim on the first home visit', () async {
    final service = buildService();

    await service.recordHomeVisit();
    expect(await service.claimHomePrompt(resumeCount: 1), isFalse);
  });

  test('claims on a later home visit when a resume exists', () async {
    final service = buildService();

    await service.recordHomeVisit();
    await service.recordHomeVisit();
    expect(await service.claimHomePrompt(resumeCount: 1), isTrue);
  });

  test('does not claim when there are no resumes', () async {
    final service = buildService();

    await service.recordHomeVisit();
    await service.recordHomeVisit();
    expect(await service.claimHomePrompt(resumeCount: 0), isFalse);
  });

  test('claims on a later visit even with more than one resume', () async {
    final service = buildService();

    await service.recordHomeVisit();
    await service.recordHomeVisit();
    expect(await service.claimHomePrompt(resumeCount: 2), isTrue);
  });

  test('does not claim while a prompt is in flight', () async {
    final service = buildService();

    await service.recordHomeVisit();
    await service.recordHomeVisit();
    expect(await service.claimHomePrompt(resumeCount: 1), isTrue);
    expect(await service.claimHomePrompt(resumeCount: 1), isFalse);
  });

  test('claims again after deferral is cleared by next home visit', () async {
    final service = buildService();

    await service.recordHomeVisit();
    await service.recordHomeVisit();
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

    await service.recordHomeVisit();
    await service.recordHomeVisit();
    expect(await service.claimHomePrompt(resumeCount: 1), isFalse);
  });

  test('value-moment prompt can fire before a second home visit', () async {
    final service = buildService();

    expect(await service.claimValueMomentPrompt(), isTrue);
  });

  test('value-moment prompt does not fire after the user has rated', () async {
    ratingCompleted = true;
    final service = buildService();

    expect(await service.claimValueMomentPrompt(), isFalse);
  });

  test('promptAfterValueMoment requests the native review', () async {
    final service = buildService();

    await service.promptAfterValueMoment();
    expect(requestNativeReviewCalls, 1);
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
