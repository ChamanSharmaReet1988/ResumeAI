import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/core/services/premium_store_messages.dart';

void main() {
  test('maps StoreKit technical errors to friendly text', () {
    expect(
      PremiumStoreMessages.friendly(
        rawMessage: 'StoreKit: Failed to get response from platform.',
        fallback: PremiumStoreMessages.productsUnavailable,
      ),
      PremiumStoreMessages.productsUnavailable,
    );
    expect(
      PremiumStoreMessages.friendly(
        rawMessage: 'SKError payment cancelled',
      ),
      'Purchase canceled.',
    );
    expect(
      PremiumStoreMessages.friendly(
        rawMessage: 'some unknown PlatformException(code: xyz)',
      ),
      isNot(contains('PlatformException')),
    );
  });
}
