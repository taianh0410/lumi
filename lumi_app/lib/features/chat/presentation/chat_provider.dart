import 'dart:typed_data';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../data/chat_backend_service.dart';

final chatBackendServiceProvider = Provider<ChatBackendService>(
  (ref) => ChatBackendService(),
);

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;
}

class ChatState {
  const ChatState({
    required this.isUploading,
    required this.isSending,
    required this.messages,
    required this.userId,
    required this.roomId,
    this.pdfBytes,
    this.pdfName,
    this.errorMessage,
  });

  final bool isUploading;
  final bool isSending;
  final List<ChatMessage> messages;
  final String userId;
  final String roomId;
  final Uint8List? pdfBytes;
  final String? pdfName;
  final String? errorMessage;

  bool get isLoading => isSending;

  factory ChatState.initial({String userId = 'anonymous'}) {
    return ChatState(
      isUploading: false,
      isSending: false,
      userId: userId,
      roomId: _generateRoomId(),
      messages: [
        ChatMessage(
          id: 'seed-1',
          text:
              'Chào bạn, hãy tải PDF ở panel trái và hỏi mình một câu Socratic.',
          isUser: false,
          createdAt: DateTime.now(),
        ),
      ],
    );
  }

  ChatState copyWith({
    bool? isUploading,
    bool? isSending,
    List<ChatMessage>? messages,
    String? userId,
    String? roomId,
    Uint8List? pdfBytes,
    String? pdfName,
    String? errorMessage,
    bool clearPdf = false,
    bool clearError = false,
  }) {
    return ChatState(
      isUploading: isUploading ?? this.isUploading,
      isSending: isSending ?? this.isSending,
      messages: messages ?? this.messages,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      pdfBytes: clearPdf ? null : pdfBytes ?? this.pdfBytes,
      pdfName: clearPdf ? null : pdfName ?? this.pdfName,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final chatProvider = StateNotifierProvider<ChatController, ChatState>(
  (ref) => ChatController(
    ref.read(chatBackendServiceProvider),
    userId: ref.read(authProvider).user?.id ?? 'anonymous',
  ),
);

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._chatBackendService, {required String userId})
      : super(ChatState.initial(userId: userId));

  final ChatBackendService _chatBackendService;

  Future<void> loadPdf() async {
    state = state.copyWith(isUploading: true, clearError: true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        state = state.copyWith(isUploading: false);
        return;
      }

      final file = result.files.single;
      if (file.bytes == null) {
        throw StateError('Không đọc được dữ liệu PDF. Hãy thử chọn lại file.');
      }

      state = state.copyWith(pdfBytes: file.bytes, pdfName: file.name);

      await _chatBackendService.uploadPdf(
        bytes: file.bytes!,
        fileName: file.name,
        roomId: state.roomId,
        userId: state.userId,
      );

      state = state.copyWith(isUploading: false, clearError: true);
    } catch (error) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: _describeError(error),
      );
    }
  }

  void clearPdf() {
    state = state.copyWith(clearPdf: true, clearError: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    final userMessage = ChatMessage(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      text: trimmedText,
      isUser: true,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      isSending: true,
      messages: <ChatMessage>[...state.messages, userMessage],
      clearError: true,
    );

    try {
      final response = await _chatBackendService.sendQuestion(
        question: trimmedText,
        roomId: state.roomId,
        userId: state.userId,
      );

      final assistantMessage = ChatMessage(
        id: 'bot-${DateTime.now().microsecondsSinceEpoch}',
        text: response.answer,
        isUser: false,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        isSending: false,
        messages: <ChatMessage>[...state.messages, assistantMessage],
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isSending: false,
        errorMessage: _describeError(error),
      );
    }
  }

  String _describeError(Object error) {
    if (error is BackendApiException) {
      return error.message;
    }

    return error.toString();
  }
}

String _generateRoomId() {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random();
  final buffer = StringBuffer('room_');

  for (var index = 0; index < 16; index++) {
    buffer.write(alphabet[random.nextInt(alphabet.length)]);
  }

  return buffer.toString();
}
