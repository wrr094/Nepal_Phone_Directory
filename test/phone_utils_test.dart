import 'package:flutter_test/flutter_test.dart';
import 'package:nepal_helpline/core/utils/phone_utils.dart';

void main() {
  test('splits multiple phone numbers without numeric conversion', () {
    final numbers = PhoneUtils.splitMultiplePhoneNumbers(
      '01-5550000; 100 / +977-01-4444444',
    );

    expect(numbers, ['01-5550000', '100', '+977-01-4444444']);
  });

  test('normalizes dialable phone while preserving short codes', () {
    expect(PhoneUtils.normalizePhoneForCall('01-5550000'), '015550000');
    expect(PhoneUtils.normalizePhoneForCall('100'), '100');
    expect(PhoneUtils.isShortCode('1098'), isTrue);
  });

  test(
    'recognizes expected Nepal personal emergency contact phone formats',
    () {
      expect(PhoneUtils.isRecognizedNepalPersonalPhone('9856021719'), isTrue);
      expect(PhoneUtils.isRecognizedNepalPersonalPhone('061616161'), isTrue);
      expect(
        PhoneUtils.isRecognizedNepalPersonalPhone('+9779856021719'),
        isTrue,
      );
      expect(PhoneUtils.isRecognizedNepalPersonalPhone('+97761616161'), isTrue);
      expect(PhoneUtils.isRecognizedNepalPersonalPhone('12345'), isFalse);
    },
  );
}
