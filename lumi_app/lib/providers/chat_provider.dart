import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/network/api_client.dart';
import '../models/message_model.dart';

final chatProvider = StateNotifierProvider.autoDispose.family<ChatNotifier, ChatState, String>(
  (ref, groupId) => ChatNotifier(groupId: groupId),
);

class ChatState {
  const ChatState({
    required this.messages,
    required this.isLoading,
    this.errorMessage,
  });

  final List<MessageModel> messages;
  final bool isLoading;
  final String? errorMessage;

  const ChatState.initial()
      : messages = const <MessageModel>[],
        isLoading = false,
        errorMessage = null;

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier({required this.groupId})
      : _dio = ApiClient.instance.dio,
        _socket = io.io(
          ApiClient.instance.dio.options.baseUrl.replaceFirst(RegExp(r'/api$'), ''),
          <String, dynamic>{
            'transports': ['websocket'],
            'autoConnect': false,
          },
        ),
        super(const ChatState.initial()) {
    _socket.onConnect((_) {
      if (_currentGroupId != null &&
          _currentGroupId!.isNotEmpty &&
          !_hasJoinedCurrentGroup) {
        _socket.emit('join_group', _currentGroupId);
        _hasJoinedCurrentGroup = true;
      }
    });

    _socket.on('receive_message', (data) {
      final message = _parseMessage(data);
      if (message == null) {
        return;
      }

      _appendMessage(message);
    });

    _socket.onDisconnect((_) {
      _hasJoinedCurrentGroup = false;
    });
  }

  final String groupId;
  final Dio _dio;
  final io.Socket _socket;

  String? _currentGroupId;
  bool _hasJoinedCurrentGroup = false;

  Future<void> connectAndJoin(String groupId) async {
    _currentGroupId = groupId;
    _hasJoinedCurrentGroup = true;
    state = state.copyWith(isLoading: true, clearError: true);

    if (!_socket.connected) {
      _socket.connect();
    }

    _socket.emit('join_group', groupId);

    try {
      final response = await _dio.get<dynamic>('/api/messages/$groupId');
      final payload = _asMap(response.data);
      final rawMessages = payload['messages'];

      if (rawMessages is! List) {
        state = state.copyWith(isLoading: false, messages: const <MessageModel>[]);
        return;
      }

      final history = rawMessages
          .whereType<Map>()
          .map((item) => MessageModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      state = state.copyWith(isLoading: false, messages: _mergeMessages(history));
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _extractMessage(error),
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  void sendMessage(String groupId, String senderId, String content) {
    final trimmedContent = content.trim();
    if (groupId.isEmpty || senderId.isEmpty || trimmedContent.isEmpty) {
      return;
    }

    if (!_socket.connected) {
      _socket.connect();
    }

    _socket.emit('send_message', <String, dynamic>{
      'groupId': groupId,
      'senderId': senderId,
      'content': trimmedContent,
    });
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _socket.disconnect();
    super.dispose();
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return const <String, dynamic>{};
  }

  MessageModel? _parseMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return MessageModel.fromJson(data);
    }
    if (data is Map) {
      return MessageModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  void _appendMessage(MessageModel message) {
    if (message.id.isNotEmpty && state.messages.any((item) => item.id == message.id)) {
      return;
    }

    state = state.copyWith(messages: [...state.messages, message]);
  }

  List<MessageModel> _mergeMessages(List<MessageModel> history) {
    final merged = <MessageModel>[];
    final seenIds = <String>{};

    for (final message in [...state.messages, ...history]) {
      if (message.id.isNotEmpty) {
        if (seenIds.add(message.id)) {
          merged.add(message);
        }
      } else {
        merged.add(message);
      }
    }

    return merged;
  }

  String _extractMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }
    return 'Không thể tải lịch sử tin nhắn.';
  }
}