import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';

class BackendApiException implements Exception {
  BackendApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final Object? detail;

  @override
  String toString() => message;
}

class PdfUploadResult {
  const PdfUploadResult({
    required this.message,
    required this.fileName,
    required this.fileHash,
    required this.scopeType,
    required this.scopeId,
    required this.pages,
    required this.chunks,
    required this.collection,
  });

  final String message;
  final String fileName;
  final String fileHash;
  final String scopeType;
  final String scopeId;
  final int pages;
  final int chunks;
  final String collection;

  factory PdfUploadResult.fromJson(Map<String, dynamic> json) {
    return PdfUploadResult(
      message: json['message']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      fileHash: json['file_hash']?.toString() ?? '',
      scopeType: json['scope_type']?.toString() ?? 'global',
      scopeId: json['scope_id']?.toString() ?? 'global',
      pages: _asInt(json['pages']),
      chunks: _asInt(json['chunks']),
      collection: json['collection']?.toString() ?? '',
    );
  }
}

class SocraticChatResult {
  const SocraticChatResult({
    required this.message,
    required this.answer,
    required this.scopeType,
    required this.scopeId,
    required this.sources,
  });

  final String message;
  final String answer;
  final String scopeType;
  final String scopeId;
  final List<Map<String, dynamic>> sources;

  factory SocraticChatResult.fromJson(Map<String, dynamic> json) {
    final sources = <Map<String, dynamic>>[];
    final rawSources = json['sources'];
    if (rawSources is List) {
      for (final item in rawSources) {
        if (item is Map<String, dynamic>) {
          sources.add(item);
        } else if (item is Map) {
          sources.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return SocraticChatResult(
      message: json['message']?.toString() ?? '',
      answer: json['answer']?.toString() ?? json['message']?.toString() ?? '',
      scopeType: json['scope_type']?.toString() ?? 'global',
      scopeId: json['scope_id']?.toString() ?? 'global',
      sources: sources,
    );
  }
}

class ChatBackendService {
  ChatBackendService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  Future<PdfUploadResult> uploadPdf({
    required Uint8List bytes,
    required String fileName,
    required String roomId,
    required String userId,
  }) async {
    final formData = FormData();
    formData.files.add(
      MapEntry('file', MultipartFile.fromBytes(bytes, filename: fileName)),
    );

    formData.fields.add(MapEntry('room_id', roomId.trim()));
    formData.fields.add(MapEntry('user_id', userId.trim()));

    try {
      final response = await _dio.post<dynamic>(
        '/api/upload',
        data: formData,
        options: Options(contentType: Headers.multipartFormDataContentType),
      );

      final payload = _asJsonMap(
        response.data,
        fallbackMessage:
            'Upload thành công nhưng phản hồi backend không hợp lệ.',
      );
      return PdfUploadResult.fromJson(payload);
    } on DioException catch (error) {
      throw BackendApiException(
        _describeDioException(
          error,
          fallbackMessage: 'Không thể upload PDF lên backend_api.',
        ),
        statusCode: error.response?.statusCode,
        detail: error.response?.data,
      );
    }
  }

  Future<SocraticChatResult> sendQuestion({
    required String question,
    required String roomId,
    required String userId,
    int topK = AppConstants.defaultTopK,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/chat',
        data: <String, dynamic>{
          'question': question,
          'room_id': roomId.trim(),
          'user_id': userId.trim(),
          'top_k': topK,
        },
      );

      final payload = _asJsonMap(
        response.data,
        fallbackMessage: 'Phản hồi chat từ backend không hợp lệ.',
      );
      return SocraticChatResult.fromJson(payload);
    } on DioException catch (error) {
      throw BackendApiException(
        _describeDioException(
          error,
          fallbackMessage: 'Không thể gửi câu hỏi tới backend_api.',
        ),
        statusCode: error.response?.statusCode,
        detail: error.response?.data,
      );
    }
  }
}

Map<String, dynamic> _asJsonMap(
  Object? data, {
  required String fallbackMessage,
}) {
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }

  throw BackendApiException(fallbackMessage, detail: data);
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _describeDioException(
  DioException error, {
  required String fallbackMessage,
}) {
  final responseData = error.response?.data;
  if (responseData is Map) {
    final message = responseData['message']?.toString();
    final detail = responseData['detail'];
    if (message != null && message.isNotEmpty) {
      if (detail != null && detail.toString().isNotEmpty) {
        return '$message: $detail';
      }
      return message;
    }
    if (detail != null && detail.toString().isNotEmpty) {
      return detail.toString();
    }
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.connectionError:
    case DioExceptionType.transformTimeout:
      return 'Không thể kết nối tới backend_api. Hãy kiểm tra mạng hoặc service backend.';
    case DioExceptionType.badCertificate:
      return 'Kết nối HTTPS không hợp lệ.';
    case DioExceptionType.cancel:
      return 'Yêu cầu đã bị hủy.';
    case DioExceptionType.badResponse:
      return fallbackMessage;
    case DioExceptionType.unknown:
      return error.message ?? fallbackMessage;
  }
}
