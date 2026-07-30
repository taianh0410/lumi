/// Models cho MongoDB-backed chat session & messages.
class ChatSessionModel {
  const ChatSessionModel({
    required this.id,
    required this.roomId,
    required this.title,
    required this.createdAt,
  });

  final String id;
  final String roomId;
  final String title;
  final DateTime createdAt;

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    final raw = json['session'] as Map<String, dynamic>? ?? json;
    return ChatSessionModel(
      id: raw['id']?.toString() ?? raw['_id']?.toString() ?? '',
      roomId: raw['roomId']?.toString() ?? '',
      title: raw['title']?.toString() ?? 'Phiên học mới',
      createdAt: _parseDate(raw['createdAt']),
    );
  }
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.sessionId,
    required this.sender,
    required this.content,
    required this.createdAt,
    this.metadata = const {},
  });

  final String id;
  final String sessionId;

  /// 'user' hoặc 'ai'
  final String sender;
  final String content;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  bool get isUser => sender == 'user';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      sender: json['sender']?.toString() ?? 'ai',
      content: json['content']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt']),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
    );
  }

  /// Tạo từ response sendMessage (trả về userMessage + aiMessage)
  static List<ChatMessageModel> fromSendResponse(Map<String, dynamic> json) {
    final result = <ChatMessageModel>[];
    if (json['userMessage'] != null) {
      result.add(ChatMessageModel.fromJson(
          Map<String, dynamic>.from(json['userMessage'] as Map)));
    }
    if (json['aiMessage'] != null) {
      result.add(ChatMessageModel.fromJson(
          Map<String, dynamic>.from(json['aiMessage'] as Map)));
    }
    return result;
  }
}

DateTime _parseDate(Object? value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}
