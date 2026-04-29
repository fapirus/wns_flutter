import 'package:flutter_test/flutter_test.dart';
import 'package:wns_flutter/wns_flutter.dart';
import 'package:wns_flutter_example/wns_error_details.dart';

void main() {
  group('formatWnsError', () {
    test('formats typed WNS exceptions for service validation', () {
      const exception = WnsChannelRequestException(
        message: 'Channel failed',
        code: 'CHANNEL_REQUEST_FAILED',
        details: 'HRESULT: 0x80070490',
      );

      final details = formatWnsError(exception);

      expect(details.title, 'WnsChannelRequestException');
      expect(details.message, 'Channel failed');
      expect(details.code, 'CHANNEL_REQUEST_FAILED');
      expect(details.recoveryHint, WnsRecoveryHint.retryLater.name);
      expect(details.details, 'HRESULT: 0x80070490');
      expect(details.raw, contains('CHANNEL_REQUEST_FAILED'));
    });

    test('formats non-WNS errors without typed fields', () {
      final details = formatWnsError(StateError('bad state'));

      expect(details.title, 'StateError');
      expect(details.message, 'Bad state: bad state');
      expect(details.code, isNull);
      expect(details.recoveryHint, isNull);
      expect(details.details, isNull);
    });
  });
}
