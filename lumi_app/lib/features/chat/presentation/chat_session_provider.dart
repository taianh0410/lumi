import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_models.dart';
import '../data/chat_session_service.dart';

final chatSessionServiceProvider = Provider<ChatSessionService>(
  (_) => ChatSessionService(),
);

// ── State ─────────────────────────────────────────────────────────────────────

class ChatSessionState {
  const ChatSessionState({
    required this.messages,
    required this.isLoading,
    required this.isSending,
    this.session,
    this.error,
  });

  final ChatSessionModel? session;
  final List<ChatMessageModel> messages;
  final bool isLoading;  // khởi tạo session / load history
  final bool isSending;  // đang chờ AI trả lời
  final String? error;

  factory ChatSessionState.initial() => const ChatSessionState(
        messages: [],
        isLoading: true,
        isSending: false,
      );

  ChatSessionState copyWith({
    ChatSessionModel? session,
    List<ChatMessageModel>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return ChatSessionState(
      session: session ?? this.session,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ChatSessionNotifier extends StateNotifier<ChatSessionState> {
  ChatSessionNotifier(this._service) : super(ChatSessionState.initial()) {
    _init();
  }

  final ChatSessionService _service;

  Future<void> _init() async {
    try {
      final session = await _service.createSession();
      state = state.copyWith(session: session, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || state.isSending || state.session == null) return;

    // Hiển thị tin nhắn user ngay lập tức (optimistic)
    final optimisticUser = ChatMessageModel(
      id: 'opt_${DateTime.now().microsecondsSinceEpoch}',
      sessionId: state.session!.id,
      sender: 'user',
      content: trimmed,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      isSending: true,
      messages: [...state.messages, optimisticUser],
      clearError: true,
    );

    try {
      final newMessages = await _service.sendMessage(
        sessionId: state.session!.id,
        content: trimmed,
      );

      // Thay optimistic message bằng response thật từ server
      final withoutOptimistic = state.messages
          .where((m) => m.id != optimisticUser.id)
          .toList();

      state = state.copyWith(
        isSending: false,
        messages: [...withoutOptimistic, ...newMessages],
      );
    } catch (e) {
      // Giữ lại tin nhắn optimistic, chỉ báo lỗi
      state = state.copyWith(
        isSending: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadHistory() async {
    if (state.session == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final messages = await _service.getHistory(state.session!.id);
      state = state.copyWith(isLoading: false, messages: messages);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final chatSessionProvider =
    StateNotifierProvider.autoDispose<ChatSessionNotifier, ChatSessionState>(
  (ref) => ChatSessionNotifier(ref.read(chatSessionServiceProvider)),
);
