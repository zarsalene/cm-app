import 'package:cm_app/api/models.dart';
import 'package:cm_app/app/serene_widgets.dart';
import 'package:cm_app/app/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/helpers.dart';

void main() {
  test('wait turns urgent at the limit and formats hours', () {
    expect(waitSeverity(urgentWaitMinutes - 1), WaitSeverity.waiting);
    expect(waitSeverity(urgentWaitMinutes), WaitSeverity.urgent);
    expect(Strings.waiting(18), "18m d'attente");
    expect(Strings.waiting(65), "1h05 d'attente");
  });

  testWidgets('HandoffSwitch reports the other mode and ignores busy taps', (
    tester,
  ) async {
    final taps = <ChatMode>[];
    var busy = false;
    await tester.pumpApp(
      StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: Column(
            children: [
              HandoffSwitch(
                mode: ChatMode.human,
                busy: busy,
                onChanged: taps.add,
              ),
              TextButton(
                onPressed: () => setState(() => busy = true),
                child: const Text('busy'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text(Strings.youActive));
    await tester.tap(find.text(Strings.botAuto));
    expect(taps, [ChatMode.bot]);

    await tester.tap(find.text('busy'));
    await tester.pump();
    await tester.tap(find.text(Strings.botAuto));
    expect(taps, [ChatMode.bot]);
  });
}
