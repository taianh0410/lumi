import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/friend_service.dart';

final friendServiceProvider = Provider<FriendService>((ref) => FriendService());

class FriendState {
  const FriendState({
    required this.isLoading,
    required this.friends,
    required this.pendingRequests,
    required this.hasLoadedData,
    this.lastActionMessage,
    this.errorMessage,
  });

  final bool isLoading;
  final List<UserModel> friends;
  final List<UserModel> pendingRequests;
  final bool hasLoadedData;
  final String? lastActionMessage;
  final String? errorMessage;

  const FriendState.initial()
      : isLoading = false,
        friends = const <UserModel>[],
        pendingRequests = const <UserModel>[],
        hasLoadedData = false,
        lastActionMessage = null,
        errorMessage = null;

  FriendState copyWith({
    bool? isLoading,
    List<UserModel>? friends,
    List<UserModel>? pendingRequests,
    bool? hasLoadedData,
    String? lastActionMessage,
    String? errorMessage,
    bool clearMessage = false,
    bool clearError = false,
  }) {
    return FriendState(
      isLoading: isLoading ?? this.isLoading,
      friends: friends ?? this.friends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      hasLoadedData: hasLoadedData ?? this.hasLoadedData,
      lastActionMessage: clearMessage
          ? null
          : lastActionMessage ?? this.lastActionMessage,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class FriendNotifier extends StateNotifier<FriendState> {
  FriendNotifier(this._service) : super(const FriendState.initial());

  final FriendService _service;

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    try {
      final results = await Future.wait<List<UserModel>>([
        _service.getFriends(),
        _service.getPendingRequests(),
      ]);
      state = state.copyWith(
        isLoading: false,
        friends: results[0],
        pendingRequests: results[1],
        hasLoadedData: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        hasLoadedData: true,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> fetchPendingRequests() async {
    state = state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    try {
      final requests = await _service.getPendingRequests();
      state = state.copyWith(
        isLoading: false,
        pendingRequests: requests,
        hasLoadedData: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        hasLoadedData: true,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> sendRequest(String targetUserId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    try {
      await _service.sendRequest(targetUserId);
      state = state.copyWith(
        isLoading: false,
        lastActionMessage: 'Đã gửi lời mời kết bạn.',
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> acceptRequest(String requesterId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    try {
      await _service.acceptRequest(requesterId);
      state = state.copyWith(
        isLoading: false,
        friends: await _service.getFriends(),
        pendingRequests: state.pendingRequests
            .where((user) => user.id != requesterId)
            .toList(),
        lastActionMessage: 'Đã chấp nhận lời mời kết bạn.',
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }
}

final friendProvider = StateNotifierProvider<FriendNotifier, FriendState>(
  (ref) => FriendNotifier(ref.read(friendServiceProvider)),
);