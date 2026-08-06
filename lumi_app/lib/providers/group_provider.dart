import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/group_model.dart';
import '../services/group_service.dart';

final groupServiceProvider = Provider<GroupService>((ref) => GroupService());

class GroupState {
  const GroupState({
    required this.groups,
    required this.isLoading,
    required this.hasLoaded,
    this.errorMessage,
  });

  final List<GroupModel> groups;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;

  const GroupState.initial()
      : groups = const <GroupModel>[],
        isLoading = false,
        hasLoaded = false,
        errorMessage = null;

  GroupState copyWith({
    List<GroupModel>? groups,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GroupState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class GroupNotifier extends StateNotifier<GroupState> {
  GroupNotifier(this._service) : super(const GroupState.initial());

  final GroupService _service;

  Future<void> fetchGroups() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final groups = await _service.getMyGroups();
      state = state.copyWith(groups: groups, isLoading: false, hasLoaded: true);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> addGroup(String name, List<String> memberIds) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final createdGroup = await _service.createGroup(name, memberIds);
      final updatedGroups = [createdGroup, ...state.groups];
      state = state.copyWith(groups: updatedGroups, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<GroupModel> openDirectChat(String friendId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final directGroup = await _service.getOrCreateDirectChat(friendId);
      final exists = state.groups.any((group) => group.id == directGroup.id);
      final updatedGroups = exists ? state.groups : [directGroup, ...state.groups];

      state = state.copyWith(groups: updatedGroups, isLoading: false);
      return directGroup;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
      rethrow;
    }
  }
}

final groupProvider = StateNotifierProvider<GroupNotifier, GroupState>(
  (ref) => GroupNotifier(ref.read(groupServiceProvider)),
);