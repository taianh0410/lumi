import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import 'chat_models.dart';

/// Giao tiếp với /api/chat/* trên Backend Node.js (MongoDB-backed).
/// Token được tự động inject bởi _AuthInterceptor trong DioClient.
class ChatSessionService {
  ChatSessionService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  /// POST /api/chat/session → trả về ChatSessionModel
  Future<ChatSessionModel> createSession({String title = 'Phiên học mới'}) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/chat/session',
        data: {'title': title},
      );
      return ChatSessionModel.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _mapError(e, 'Không thể tạo phiên chat.');
    }
  }

  /// POST /api/chat/message → trả về [userMessage, aiMessage]
  Future<List<ChatMessageModel>> sendMessage({
    required String sessionId,
    required String content,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/chat/message',
        data: {'sessionId': sessionId, 'content': content},
      );
      return ChatMessageModel.fromSendResponse(_asMap(response.data));
    } on DioException catch (e) {
      throw _mapError(e, 'Không thể gửi tin nhắn.');
    }
  }

  /// GET /api/chat/session/:sessionId → lịch sử tin nhắn
  Future<List<ChatMessageModel>> getHistory(String sessionId) async {
    try {
      final response =
          await _dio.get<dynamic>('/api/chat/session/$sessionId');
      final data = _asMap(response.data);
      final rawMessages = data['messages'];
      if (rawMessages is! List) return [];
      return rawMessages
          .whereType<Map>()
          .map((m) => ChatMessageModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e, 'Không thể tải lịch sử chat.');
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Phản hồi server không hợp lệ.');
  }

  Exception _mapError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message']?.toString();
      if (msg != null && msg.isNotEmpty) return Exception(msg);
    }
    if (e.response?.statusCode == 401) {
      return Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
    }
    return Exception(fallback);
  }
}
