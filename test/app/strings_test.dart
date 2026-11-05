import 'package:cm_app/app/strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Strings.customerLabel', () {
    test('uses the API name when present', () {
      expect(
        Strings.customerLabel(
          '  Sana Ben Ali ',
          '1000000001234',
          platform: 'facebook',
        ),
        'Sana Ben Ali',
      );
    });

    for (final name in [null, '', '   ']) {
      test('falls back to channel + last 4 when name is ${name ?? 'null'}', () {
        expect(
          Strings.customerLabel(name, '21612341234', platform: 'whatsapp'),
          'Client WhatsApp …1234',
        );
        expect(
          Strings.customerLabel(name, '1000000005678', platform: 'facebook'),
          'Client Facebook …5678',
        );
      });
    }

    test('keeps a short sender id whole', () {
      expect(
        Strings.customerLabel(null, '42', platform: 'whatsapp'),
        'Client WhatsApp …42',
      );
    });
  });
}
