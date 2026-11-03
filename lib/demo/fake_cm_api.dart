import 'dart:async';

import 'package:cm_app/api/cm_api.dart';

/// In-memory [CmApi] for the browser preview. Never used in real builds.
class FakeCmApi implements CmApi {
  /// Creates a [FakeCmApi]; a new open escalation appears after 25 s.
  new() {
    final now = DateTime.now();
    DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));
    _escalations = [
      Escalation(
        senderId: '1000000000001',
        platform: 'facebook',
        customerName: 'Sana Ben Ali',
        reason: 'AI decided to escalate (valid end token detected)',
        escalatedAt: ago(4),
        status: 'open',
      ),
      Escalation(
        senderId: '21650123456',
        platform: 'whatsapp',
        customerName: 'Mohamed Trabelsi',
        reason: 'Le client demande un remboursement',
        escalatedAt: ago(18),
        status: 'open',
      ),
      Escalation(
        senderId: '21698761234',
        platform: 'whatsapp',
        reason: "Photo reçue: besoin d'un humain",
        escalatedAt: ago(42),
        status: 'open',
      ),
      Escalation(
        senderId: '1000000000004',
        platform: 'facebook',
        customerName: 'Ines Gharbi',
        reason: 'Le client demande un remboursement',
        escalatedAt: ago(180),
        status: 'closed',
      ),
      Escalation(
        senderId: '21622334455',
        platform: 'whatsapp',
        customerName: 'Walid Jlassi',
        reason: 'AI decided to escalate (valid end token detected)',
        escalatedAt: ago(1500),
        status: 'closed',
      ),
    ];
    // Held so the timer is not garbage collected.
    _late = Timer(const Duration(seconds: 25), () {
      _escalations = [
        Escalation(
          senderId: '21655667788',
          platform: 'whatsapp',
          customerName: 'Rim Mansouri',
          reason: 'Le client demande un remboursement',
          escalatedAt: DateTime.now(),
          status: 'open',
        ),
        ..._escalations,
      ];
    });
  }

  static const _delay = Duration(milliseconds: 250);

  late List<Escalation> _escalations;
  final _modes = <String, ChatMode>{};
  final _extra = <String, List<ChatMessage>>{};
  // ignore: unused_field, kept only so the timer has an owner
  late final Timer _late;

  String _key(String id, String platform) => '$platform/$id';

  Future<T> _wait<T>(T Function() run) =>
      Future<void>.delayed(_delay).then((_) => run());

  @override
  Future<Session> login(String username, String password) => _wait(() {
    if (username != 'demo' || password != 'demo') {
      throw const InvalidLoginException();
    }
    return Session(
      token: 'demo-token',
      username: 'demo',
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
  });

  @override
  Future<List<Escalation>> escalations() =>
      _wait(() => List.unmodifiable(_escalations));

  @override
  Future<Chat> chat(String senderId, String platform) => _wait(() {
    final found = _escalations.where(
      (e) => e.senderId == senderId && e.platform == platform,
    );
    final key = _key(senderId, platform);
    return Chat(
      senderId: senderId,
      platform: platform,
      customerName: found.isEmpty ? null : found.first.customerName,
      reason: found.isEmpty ? '' : found.first.reason,
      mode: _modes[key] ?? ChatMode.human,
      messages: [..._script(senderId), ...?_extra[key]],
    );
  });

  @override
  Future<void> reply(String senderId, String platform, String text) =>
      _wait(() {
        if (text.toLowerCase().contains('fail')) {
          throw const SendFailedException('demo');
        }
        (_extra[_key(senderId, platform)] ??= []).add(
          ChatMessage(role: 'bot', text: text, at: DateTime.now()),
        );
      });

  @override
  Future<void> giveBack(String senderId, String platform) => _wait(() {
    _modes[_key(senderId, platform)] = ChatMode.bot;
    _escalations = [
      for (final e in _escalations)
        if (e.senderId == senderId && e.platform == platform)
          Escalation(
            senderId: e.senderId,
            platform: e.platform,
            customerName: e.customerName,
            reason: e.reason,
            escalatedAt: e.escalatedAt,
            status: 'closed',
          )
        else
          e,
    ];
  });

  @override
  Future<void> logout() => _wait(() {});

  List<ChatMessage> _script(String senderId) {
    final now = DateTime.now();
    var minutes = 20;
    ChatMessage m(String role, String text) {
      minutes -= 2;
      return ChatMessage(
        role: role,
        text: text,
        at: now.subtract(Duration(minutes: minutes)),
      );
    }

    // Tunisian darija for WhatsApp ids, French for the others.
    if (senderId.startsWith('216')) {
      return [
        m('customer', 'عسلامة، عندكم الفستان هذا بالكحلي؟'),
        m('bot', 'Bonjour ! Oui, il est disponible en bleu marine.'),
        m('customer', 'بقداش وكيفاش نخلص؟'),
        m('bot', 'Le prix est 89 DT. Paiement à la livraison possible.'),
        m('customer', 'ياسر غالي، نحب نرجّع الكوموند اللي فاتت و ناخذ فلوسي'),
        m('bot', 'Je transfère votre demande à un conseiller.'),
        m('customer', 'برّا بالله خلّيني نحكي مع واحد حقيقي'),
        m('customer', 'مازلت نستنى'),
      ];
    }
    return [
      m('customer', "Bonjour, ma commande n'est toujours pas arrivée."),
      m('bot', 'Bonjour ! Pouvez-vous me donner votre numéro de commande ?'),
      m('customer', "C'est le 48213, passée il y a 10 jours."),
      m('bot', 'Je vérifie cela pour vous.'),
      m('customer', 'Je veux un remboursement, ça suffit.'),
      m('bot', 'Je vous mets en relation avec un conseiller.'),
      m('customer', "Merci, j'attends."),
    ];
  }
}
