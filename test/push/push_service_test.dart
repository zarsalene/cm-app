import 'package:cm_app/push/push_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'parsePushTarget accepts only a numeric sender and a known platform',
    () {
      expect(
        parsePushTarget({'sender_id': '1234567890', 'platform': 'facebook'}),
        const PushTarget(senderId: '1234567890', platform: 'facebook'),
      );
      expect(
        parsePushTarget({'sender_id': '21690431500', 'platform': 'whatsapp'}),
        const PushTarget(senderId: '21690431500', platform: 'whatsapp'),
      );
      expect(
        parsePushTarget({'sender_id': '12345/../x', 'platform': 'facebook'}),
        isNull,
      );
      expect(
        parsePushTarget({'sender_id': '1234567890', 'platform': 'telegram'}),
        isNull,
      );
      expect(parsePushTarget(<String, dynamic>{}), isNull);
      expect(parsePushTarget({'sender_id': '1234567890'}), isNull);
    },
  );
}
