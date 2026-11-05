import 'dart:convert';

import 'package:cm_app/api/cm_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('escalations() throws UnauthorizedException on 401', () {
    final api = CmApi(
      MockClient((_) async => http.Response('{"error":"unauthorized"}', 401)),
      token: () async => 'tok',
    );

    expect(api.escalations(), throwsA(isA<UnauthorizedException>()));
  });

  test('conversations() parses items and nullable fields', () async {
    late Map<String, dynamic> sent;
    final api = CmApi(
      MockClient((request) async {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return _json({
          'items': [
            {
              'sender_id': '21650123456',
              'platform': 'whatsapp',
              'customer_name': 'Mohamed Trabelsi',
              'last_message': 'Bonjour',
              'last_seen': '2026-01-02T10:00:00.000Z',
              'mode': 'bot',
              'status': 'active',
              'reason': '',
              'escalated_at': null,
            },
            {
              'sender_id': '1000000000001',
              'platform': 'facebook',
              'customer_name': null,
              'last_message': '',
              'last_seen': null,
              'mode': 'human',
              'status': 'open',
              'reason': 'Demande un humain',
              'escalated_at': '2026-01-01T09:00:00.000Z',
            },
          ],
        });
      }),
      token: () async => 'tok',
    );

    final items = await api.conversations();

    expect(sent, {'action': 'conversations'});
    expect(items, hasLength(2));
    expect(items.first.senderId, '21650123456');
    expect(items.first.mode, ChatMode.bot);
    expect(items.first.botActive, isTrue);
    expect(items.first.lastSeen, DateTime.utc(2026, 1, 2, 10));
    expect(items.last.customerName, isNull);
    expect(items.last.mode, ChatMode.human);
    expect(items.last.needsHuman, isTrue);
    expect(items.last.reason, 'Demande un humain');
  });

  test('setAiMode() sends the mode and parses the applied mode', () async {
    late Map<String, dynamic> sent;
    final api = CmApi(
      MockClient((request) async {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return _json({'ok': true, 'mode': 'human', 'status': 'open'});
      }),
      token: () async => 'tok',
    );

    final applied = await api.setAiMode(
      '21650123456',
      'whatsapp',
      ChatMode.human,
    );

    expect(applied, ChatMode.human);
    expect(sent, {
      'action': 'set_ai_mode',
      'sender_id': '21650123456',
      'platform': 'whatsapp',
      'mode': 'human',
    });
  });

  test('setAiMode() rejects an unknown mode', () async {
    final api = CmApi(
      MockClient((_) async => _json({'mode': 'copilot'})),
      token: () async => 'tok',
    );

    expect(
      api.setAiMode('21650123456', 'whatsapp', ChatMode.human),
      throwsA(isA<ApiException>()),
    );
  });
}
