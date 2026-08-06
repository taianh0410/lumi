import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/user_model.dart';

class FriendService {
  FriendService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<List<UserModel>> getFriends() async {
    try {
      final response = await _dio.get<dynamic>('/api/friends/list');
      final payload = _asMap(response.data);
      final rawItems = payload['friends'];

      if (rawItems is! List) {
        return const <UserModel>[];
      }

      return rawItems
          .whereType<Map>()
          .map((item) => UserModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const <UserModel>[];
      }
      throw _mapError(error, fallback: 'Không thể tải danh sách bạn bè.');
    }
  }

  Future<void> sendRequest(String targetUserId) async {
    try {
      await _dio.post<dynamic>(
        '/api/friends/request',
        data: {'targetUserId': targetUserId},
      );
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Không thể gửi lời mời kết bạn.');
    }
  }

  Future<void> acceptRequest(String requesterId) async {
    try {
      await _dio.post<dynamic>(
        '/api/friends/accept',
        data: {'requesterId': requesterId},
      );
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Không thể chấp nhận lời mời kết bạn.');
    }
  }

  Future<List<UserModel>> getPendingRequests() async {
    try {
      final response = await _dio.get<dynamic>('/api/friends/pending');
      final payload = _asMap(response.data);
      final rawItems = payload['requests'];

      if (rawItems is! List) {
        return const <UserModel>[];
      }

      return rawItems
          .whereType<Map>()
          .map((item) => UserModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const <UserModel>[];
      }
      throw _mapError(error, fallback: 'Không thể tải danh sách lời mời kết bạn.');
    }
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

  Exception _mapError(DioException error, {required String fallback}) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return Exception(message);
      }
    }

    if (error.response?.statusCode == 401) {
      return Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
    }

    return Exception(fallback);
  }
}