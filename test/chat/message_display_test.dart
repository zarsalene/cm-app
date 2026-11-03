import 'package:cm_app/chat/chat_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cleanMessageText', () {
    test('drops the escalate token and the leaked prompt memory', () {
      const raw =
          'Merci, on vous envoie la vidéo.\n\n'
          'Le client Sana demande une vidéo.\n'
          '{"history": ["Assistant: x", "Client: y"]} [[ESCALATE]]';
      expect(
        cleanMessageText(raw),
        'Merci, on vous envoie la vidéo.\n\n'
        'Le client Sana demande une vidéo.',
      );
    });

    test('keeps a normal message and never returns an empty one', () {
      expect(cleanMessageText('Bonjour !'), 'Bonjour !');
      const onlyToken = '[[ESCALATE]]';
      expect(cleanMessageText(onlyToken), onlyToken);
    });
  });
}
