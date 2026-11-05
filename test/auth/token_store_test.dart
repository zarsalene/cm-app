import 'package:cm_app/auth/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements FlutterSecureStorage;

void main() {
  test('write() throws when secure storage fails, so login cannot loop', () {
    final storage = _MockStorage();
    when(
      () => storage.write(key: any(named: 'key'), value: any(named: 'value')),
    ).thenThrow(Exception('keystore'));

    expect(
      TokenStore(storage).write(token: 't', username: 'cm', rememberMe: true),
      throwsException,
    );
  });
}
