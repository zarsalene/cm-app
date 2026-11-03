// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Session _$SessionFromJson(Map<String, dynamic> json) => Session(
  token: json['token'] as String,
  username: json['username'] as String,
  expiresAt: DateTime.parse(json['expires_at'] as String),
);

Escalation _$EscalationFromJson(Map<String, dynamic> json) => Escalation(
  senderId: json['sender_id'] as String,
  platform: json['platform'] as String,
  reason: json['reason'] as String,
  escalatedAt: DateTime.parse(json['escalated_at'] as String),
  status: json['status'] as String,
  customerName: json['customer_name'] as String?,
);

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  role: json['role'] as String,
  text: json['text'] as String,
  at: json['at'] == null ? null : DateTime.parse(json['at'] as String),
);

Chat _$ChatFromJson(Map<String, dynamic> json) => Chat(
  senderId: json['sender_id'] as String,
  platform: json['platform'] as String,
  reason: json['reason'] as String,
  mode: $enumDecode(_$ChatModeEnumMap, json['mode']),
  messages: (json['messages'] as List<dynamic>)
      .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
      .toList(),
  customerName: json['customer_name'] as String?,
);

const _$ChatModeEnumMap = {ChatMode.human: 'human', ChatMode.bot: 'bot'};
