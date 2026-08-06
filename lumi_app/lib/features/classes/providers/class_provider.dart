import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/class_models.dart';
import '../data/class_service.dart';

final classServiceProvider = Provider<ClassService>((_) => ClassService());

// ── State ─────────────────────────────────────────────────────────────────────

class ClassState {
  const ClassState({
    required this.classes,
    required this.isLoading,
    this.error,
  });

  final List<ClassModel> classes;
  final bool isLoading;
  final String? error;

  factory ClassState.initial() =>
      const ClassState(classes: [], isLoading: true);

  ClassState copyWith({
    List<ClassModel>? classes,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => ClassState(
        classes: classes ?? this.classes,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ClassNotifier extends StateNotifier<ClassState> {
  ClassNotifier(this._service) : super(ClassState.initial()) {
    load();
  }

  final ClassService _service;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final classes = await _service.getMyClasses();
      state = state.copyWith(classes: classes, isLoading: false);
    } on ClassException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Lỗi không xác định.');
    }
  }

  Future<bool> createClass(String name) async {
    try {
      final created = await _service.createClass(name);
      state = state.copyWith(classes: [created, ...state.classes]);
      return true;
    } on ClassException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<bool> joinClass(String joinCode) async {
    try {
      final joined = await _service.joinClass(joinCode);
      // Tránh duplicate nếu đã trong danh sách
      final already = state.classes.any((c) => c.id == joined.id);
      if (!already) {
        state = state.copyWith(classes: [joined, ...state.classes]);
      }
      return true;
    } on ClassException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final classProvider =
    StateNotifierProvider.autoDispose<ClassNotifier, ClassState>(
  (ref) => ClassNotifier(ref.read(classServiceProvider)),
);
