import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/group_model.dart';

class GroupService {
  GroupService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<GroupModel> getOrCreateDirectChat(String friendId) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/groups/direct',
        data: {'friendId': friendId},
      );

      final groupData = _extractGroupPayload(response.data);
      return GroupModel.fromJson(groupData);
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Không thể mở chat trực tiếp.');
    }
  }

  Future<GroupModel> createGroup(String name, List<String> memberIds) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/groups',
        data: {'name': name.trim(), 'memberIds': memberIds},
      );

      final groupData = _extractGroupPayload(response.data);
      return GroupModel.fromJson(groupData);
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Không thể tạo nhóm.');
    }
  }

  Future<List<GroupModel>> getMyGroups() async {
    try {
      final response = await _dio.get<dynamic>('/api/groups');
      final data = _asMap(response.data);
      final rawGroups = data['groups'];

      if (rawGroups is! List) {
        return const <GroupModel>[];
      }

      return rawGroups
          .whereType<Map>()
          .map((group) => GroupModel.fromJson(Map<String, dynamic>.from(group)))
          .toList();
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Không thể tải danh sách nhóm.');
    }
  }

  Map<String, dynamic> _extractGroupPayload(dynamic data) {
    final json = _asMap(data);
    final group = json['group'];
    if (group is Map<String, dynamic>) {
      return group;
    }
    if (group is Map) {
      return Map<String, dynamic>.from(group);
    }
    return json;
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