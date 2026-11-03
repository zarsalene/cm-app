import 'package:cm_app/api/cm_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('escalations() throws UnauthorizedException on 401', () {
    final api = CmApi(
      MockClient((_) async => http.Response('{"error":"unauthorized"}', 401)),
      token: () async => 'tok',
    );

    expect(api.escalations(), throwsA(isA<UnauthorizedException>()));
  });
}
