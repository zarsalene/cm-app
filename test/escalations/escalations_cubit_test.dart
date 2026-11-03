import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cm_app/api/cm_api.dart';
import 'package:cm_app/escalations/escalations_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockCmApi extends Mock implements CmApi;

void main() {
  final item = Escalation(
    senderId: '1234567890',
    platform: 'facebook',
    reason: 'Demande un humain',
    escalatedAt: DateTime(2026, 11, 3),
    status: 'open',
  );
  late CmApi api;
  late StreamController<void> ticks;

  blocTest<EscalationsCubit, EscalationsState>(
    'polling: a tick refreshes, 2 failures set offline, a success clears it',
    setUp: () {
      api = _MockCmApi();
      ticks = StreamController<void>();
      var calls = 0;
      when(() => api.escalations()).thenAnswer((_) async {
        calls++;
        if (calls <= 2) throw const NetworkException();
        return [item];
      });
    },
    tearDown: () => ticks.close(),
    build: () =>
        EscalationsCubit(api, onUnauthorized: () {}, ticks: () => ticks.stream),
    act: (cubit) async {
      cubit.startPolling();
      for (var i = 0; i < 3; i++) {
        ticks.add(null);
        await Future<void>.delayed(Duration.zero);
      }
    },
    expect: () => [
      const EscalationsState(),
      const EscalationsState(offline: true),
      EscalationsState(items: [item]),
    ],
    verify: (_) => verify(() => api.escalations()).called(3),
  );
}
