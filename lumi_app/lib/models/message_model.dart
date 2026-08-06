import 'user_model.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.senderId,
    required this.groupId,
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final UserModel senderId;
  final String groupId;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory MessageModel.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    return MessageModel(
      id: _readString(data, ['id', '_id']),
      senderId: _readUser(data['senderId']),
      groupId: _readGroupId(data['groupId']),
      content: _readString(data, ['content']),
      createdAt: _readDateTime(data['createdAt']),
      updatedAt: _readDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'senderId': senderId.toJson(),
      'groupId': groupId,
      'content': content,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static UserModel _readUser(dynamic rawUser) {
    if (rawUser is Map<String, dynamic>) {
      return UserModel.fromJson(rawUser);
    }
    if (rawUser is Map) {
      return UserModel.fromJson(Map<String, dynamic>.from(rawUser));
    }
    return UserModel.fromJson({'id': rawUser?.toString() ?? ''});
  }

  static String _readGroupId(dynamic rawGroupId) {
    if (rawGroupId is Map<String, dynamic>) {
      return _readString(rawGroupId, ['id', '_id']);
    }
    if (rawGroupId is Map) {
      return _readString(Map<String, dynamic>.from(rawGroupId), ['id', '_id']);
    }
    return rawGroupId?.toString().trim() ?? '';
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.tryParse(value.toString());
  }
}