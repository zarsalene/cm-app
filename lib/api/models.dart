import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

/// Login result.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class Session {
  /// Creates a [Session].
  const new({
    required this.token,
    required this.username,
    required this.expiresAt,
  });

  /// Parses the `login` response.
  factory fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);

  /// Bearer token.
  final String token;

  /// Logged-in user.
  final String username;

  /// Token expiry (ISO 8601 on the wire).
  final DateTime expiresAt;
}

/// One open or closed escalation in the list.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class Escalation {
  /// Creates an [Escalation].
  const new({
    required this.senderId,
    required this.platform,
    required this.reason,
    required this.escalatedAt,
    required this.status,
    this.customerName,
  });

  /// Parses one `escalations` item.
  factory fromJson(Map<String, dynamic> json) => _$EscalationFromJson(json);

  /// Platform sender id.
  final String senderId;

  /// `facebook` or `whatsapp`.
  final String platform;

  /// Customer name, null or empty when unknown.
  final String? customerName;

  /// Why the bot escalated.
  final String reason;

  /// When the escalation happened.
  final DateTime escalatedAt;

  /// `open` or `closed`.
  final String status;
}

/// Who handles the conversation.
enum ChatMode {
  /// A human community manager.
  human,

  /// The bot.
  bot,
}

/// One WhatsApp or Facebook conversation in the unified inbox.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class Conversation {
  /// Creates a [Conversation].
  const new({
    required this.senderId,
    required this.platform,
    required this.mode,
    required this.status,
    this.customerName,
    this.lastMessage = '',
    this.lastSeen,
    this.reason = '',
    this.escalatedAt,
  });

  /// Parses one `conversations` item.
  factory fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);

  /// Platform sender id.
  final String senderId;

  /// `facebook` or `whatsapp`.
  final String platform;

  /// Customer name, null or empty when unknown.
  final String? customerName;

  /// Last inbound message, empty when the backend has none.
  final String lastMessage;

  /// Last activity, null when unknown.
  final DateTime? lastSeen;

  /// Current handler.
  final ChatMode mode;

  /// `open` (needs a human), `closed` (handled) or `active` (bot).
  final String status;

  /// Why the bot escalated, empty when there is no escalation.
  final String reason;

  /// When the escalation happened, null when there is none.
  final DateTime? escalatedAt;

  /// True while a human handles the conversation.
  bool get needsHuman => mode == ChatMode.human;

  /// True when the bot currently answers.
  bool get botActive => mode == ChatMode.bot;

  /// Newest activity first; unknown dates go last.
  DateTime get sortAt =>
      lastSeen ??
      escalatedAt ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

/// One message in a chat.
@JsonSerializable(createToJson: false)
class ChatMessage {
  /// Creates a [ChatMessage].
  const new({required this.role, required this.text, this.at});

  /// Parses one `messages` item.
  factory fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

  /// `customer` or `bot`.
  final String role;

  /// Message text.
  final String text;

  /// Send time, null when the server has none.
  final DateTime? at;
}

/// A conversation with its last messages.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class Chat {
  /// Creates a [Chat].
  const new({
    required this.senderId,
    required this.platform,
    required this.reason,
    required this.mode,
    required this.messages,
    this.customerName,
  });

  /// Parses the `chat` response.
  factory fromJson(Map<String, dynamic> json) => _$ChatFromJson(json);

  /// Platform sender id.
  final String senderId;

  /// `facebook` or `whatsapp`.
  final String platform;

  /// Customer name, null or empty when unknown.
  final String? customerName;

  /// Why the bot escalated.
  final String reason;

  /// Current handler.
  final ChatMode mode;

  /// Last 100 messages, oldest first.
  final List<ChatMessage> messages;
}
