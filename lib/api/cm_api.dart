import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cm_app/api/models.dart';
import 'package:http/http.dart' as http;

export 'models.dart';

/// 401 on a protected call, or no token available.
class UnauthorizedException implements Exception {
  /// Creates an [UnauthorizedException].
  const new();

  @override
  String toString() => 'UnauthorizedException';
}

/// Login rejected (401 `invalid_login`).
class InvalidLoginException implements Exception {
  /// Creates an [InvalidLoginException].
  const new();

  @override
  String toString() => 'InvalidLoginException';
}

/// The platform refused the reply (502 `send_failed`).
class SendFailedException implements Exception {
  /// Creates a [SendFailedException].
  const new(this.detail);

  /// Server detail text.
  final String detail;

  @override
  String toString() => 'SendFailedException: $detail';
}

/// Any other non-2xx status, or an unreadable body.
class ApiException implements Exception {
  /// Creates an [ApiException].
  const new(this.status);

  /// HTTP status code.
  final int status;

  @override
  String toString() => 'ApiException: $status';
}

/// No connection, or the request timed out.
class NetworkException implements Exception {
  /// Creates a [NetworkException].
  const new();

  @override
  String toString() => 'NetworkException';
}

/// Client for the single CM webhook.
class CmApi {
  /// Creates a [CmApi]. `token` returns the stored bearer token, or null.
  new(this._client, {required this._token, this._baseUrl = _defaultBaseUrl});

  static const _defaultBaseUrl = String.fromEnvironment(
    'CM_API_URL',
    defaultValue: 'https://n8ntest.microzed.tn/webhook/cm-app',
  );
  static const _timeout = Duration(seconds: 15);

  final http.Client _client;
  final Future<String?> Function() _token;
  final String _baseUrl;

  /// Logs in and returns the [Session].
  Future<Session> login(String username, String password) => _post('login', {
    'username': username,
    'password': password,
  }).then((json) => _parse(() => Session.fromJson(json)));

  /// Lists escalations, open first.
  Future<List<Escalation>> escalations() => _post('escalations').then(
    (json) => _parse(
      () => (json['items'] as List<dynamic>)
          .map((e) => Escalation.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );

  /// Lists every known conversation, newest activity first.
  Future<List<Conversation>> conversations() => _post('conversations').then(
    (json) => _parse(
      () => (json['items'] as List<dynamic>)
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );

  /// Switches the conversation between the bot and a human.
  Future<ChatMode> setAiMode(String senderId, String platform, ChatMode mode) =>
      _post('set_ai_mode', {
        'sender_id': senderId,
        'platform': platform,
        'mode': mode.name,
      }).then(
        (json) => _parse(
          () => switch (json['mode']) {
            'human' => ChatMode.human,
            'bot' => ChatMode.bot,
            _ => throw const FormatException('Unknown mode'),
          },
        ),
      );

  /// Loads one conversation.
  Future<Chat> chat(String senderId, String platform) => _post('chat', {
    'sender_id': senderId,
    'platform': platform,
  }).then((json) => _parse(() => Chat.fromJson(json)));

  /// Sends [text] to the customer.
  Future<void> reply(String senderId, String platform, String text) async {
    await _post('reply', {
      'sender_id': senderId,
      'platform': platform,
      'text': text,
    });
  }

  /// Hands the conversation back to the bot.
  Future<void> giveBack(String senderId, String platform) async {
    await _post('give_back', {'sender_id': senderId, 'platform': platform});
  }

  /// Ends the session on the server.
  Future<void> logout() async {
    await _post('logout');
  }

  Future<Map<String, dynamic>> _post(
    String action, [
    Map<String, Object?> extra = const {},
  ]) async {
    final headers = {'Content-Type': 'application/json; charset=utf-8'};
    if (action != 'login') {
      final token = await _token();
      if (token == null) throw const UnauthorizedException();
      headers['Authorization'] = 'Bearer $token';
    }

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_baseUrl),
            headers: headers,
            body: jsonEncode({'action': action, ...extra}),
          )
          .timeout(_timeout);
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException();
    }

    final status = response.statusCode;
    // bodyBytes: `body` falls back to latin1 when no charset is sent.
    final body = _decode(response.bodyBytes);
    if (status >= 200 && status < 300) {
      if (body == null) throw ApiException(status);
      return body;
    }

    final error = body?['error'];
    if (status == 401) {
      throw action == 'login' && error == 'invalid_login'
          ? const InvalidLoginException()
          : const UnauthorizedException();
    }
    if (status == 502 && error == 'send_failed') {
      throw SendFailedException(body?['detail']?.toString() ?? '');
    }
    throw ApiException(status);
  }

  Map<String, dynamic>? _decode(List<int> bytes) {
    try {
      final json = jsonDecode(utf8.decode(bytes));
      return json is Map<String, dynamic> ? json : null;
    } on FormatException {
      return null;
    }
  }

  // A malformed 2xx body surfaces as ApiException, never a raw TypeError.
  T _parse<T>(T Function() parse) {
    try {
      return parse();
      // ignore: avoid_catching_errors, json_serializable throws TypeError
    } on TypeError {
      throw const ApiException(200);
    } on FormatException {
      throw const ApiException(200);
    }
  }
}
