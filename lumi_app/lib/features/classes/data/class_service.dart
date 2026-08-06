import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/network/api_client.dart';
import 'class_models.dart';

class ClassException implements Exception {
  ClassException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ClassService {
  ClassService() : _dio = ApiClient.instance.dio;

  final Dio _dio;

  Future<List<ClassModel>> getMyClasses() async {
    try {
      final res = await _dio.get<dynamic>('/api/classes/mine');
      final raw = (res.data as Map)['classes'] as List? ?? [];
      return raw
          .whereType<Map>()
          .map((m) => ClassModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } on DioException catch (e) {
      throw ClassException(_parseError(e, 'Không thể tải danh sách lớp.'));
    }
  }

  Future<ClassModel> createClass(String name, {String description = ''}) async {
    try {
      final res = await _dio.post<dynamic>(
        '/api/classes',
        data: {'name': name.trim(), 'description': description.trim()},
      );
      return ClassModel.fromJson(
          Map<String, dynamic>.from((res.data as Map)['class'] as Map));
    } on DioException catch (e) {
      throw ClassException(_parseError(e, 'Không thể tạo lớp học.'));
    }
  }

  Future<ClassModel> joinClass(String joinCode) async {
    try {
      final res = await _dio.post<dynamic>(
        '/api/classes/join',
        data: {'joinCode': joinCode.trim().toUpperCase()},
      );
      return ClassModel.fromJson(
          Map<String, dynamic>.from((res.data as Map)['class'] as Map));
    } on DioException catch (e) {
      throw ClassException(_parseError(e, 'Không thể tham gia lớp.'));
    }
  }

  Future<List<String>> uploadMaterial(
      String classId, PlatformFile file) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
          contentType: DioMediaType('application', 'pdf'),
        ),
      });
      final res = await _dio.post<dynamic>(
        '/api/classes/$classId/upload',
        data: formData,
      );
      final raw = (res.data as Map)['allTags'];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    } on DioException catch (e) {
      throw ClassException(_parseError(e, 'Không thể upload tài liệu.'));
    }
  }

  Future<Map<String, dynamic>> getHeatmapData(String classId) async {
    try {
      final res = await _dio.get<dynamic>('/api/classes/$classId/heatmap');
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {};
    } on DioException catch (e) {
      throw ClassException(_parseError(e, 'Không thể tải dữ liệu heatmap.'));
    }
  }

  String _parseError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message']?.toString();
      if (msg != null && msg.isNotEmpty) return msg;
    }
    return fallback;
  }
}
