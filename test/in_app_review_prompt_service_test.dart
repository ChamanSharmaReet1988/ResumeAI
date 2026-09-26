import 'package:flutter_test/flutter_test.dart';

import 'package:resume_app/core/services/in_app_review_prompt_service.dart';

void main() {
  late bool ratingCompleted;
  late bool hasShared;
  late int openStoreListingCalls;
  late int requestNativeReviewCalls;
  late int homeVisitCount;

  InAppReviewPromptService buildService() {
    return InAppReviewPromptService(
      readRatingCompleted: () async => ratingCompleted,
      writeRatingCompleted: () async {
        ratingCompleted = true;
      },
      readHasShared: () async => hasShared,
      writeHasShared: () async {
        hasShared = true;
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
    hasShared = false;
    openStoreListingCalls = 0;
    requestNativeReviewCalls = 0;
    homeVisitCount = 0;
  });

  test('does not claim on the first home visit even after share', () async {
    final service = buildService();

    await service.promptAfterShare();
    await service.recordHomeVisit();
    expect(await service.claimHomePrompt(resumeCount: 1), isFalse);
  });

  test('claims on 2nd home visit after one share', () async {
    final service = buildService();

    await service.promptAfterShare();
    await service.recordHomeVisit();
    await service.recordHomeVisit();
    expect(await service.claimHomePrompt(resumeCount: 1), isTrue);
  });

  test('does not claim on 2nd home visit without a share', () async {
    final service = buildService();

    await service.recordHomeVisit();
    await service.recordHomeVisit();
    expect(await service.claimHomePrompt(resumeCount: 1), isFalse);
  });

  test('does not claim when there are no resumes', () async {
    final service = buildService();

    await service.promptAfterShare();
    await service.recordHomeVisit();
    await service.recordHomeVisit();
    expect(await service.claimHomePrompt(resumeCount: 0), isFalse);
  });

  test('claims on a later visit even with more than one resume', () async {
    final service = buildService();

    await service.promptAfterShare();
    await service.recordHomeVisit();
    await service.recordHomeVisit();
    expect(await service.claimHomePrompt(resumeCount: 2), isTrue);
  });

  test('does not claim while a prompt is in flight', () async {
    final service = buildService();

    await service.promptAfterShare();
    await service.recordHomeVisit();
    await service.recordHomeVisit();
    expect(await service.claimHomePrompt(resumeCount: 1), isTrue);
    expect(await service.claimHomePrompt(resumeCount: 1), isFalse);
  });

  test('claims again after deferral is cleared by next home visit', () async {
    final service = buildService();

    await service.promptAfterShare();
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

    await service.promptAfterShare();
    await service.recordHomeVisit();
    await service.recordHomeVisit();
    expect(await service.claimHomePrompt(resumeCount: 1), isFalse);
  });

  test('promptAfterShare only records share and does not request review',
      () async {
    final service = buildService();

    await service.promptAfterShare();
    expect(hasShared, isTrue);
    expect(requestNativeReviewCalls, 0);
  });

  test('promptAfterValueMoment does not request review immediately', () async {
    final service = buildService();

    await service.promptAfterValueMoment();
    expect(requestNativeReviewCalls, 0);
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
