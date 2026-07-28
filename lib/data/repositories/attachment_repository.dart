import 'package:dio/dio.dart';
import 'package:dio/dio.dart' as dio_lib;
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';

/// Attachment repository — upload, delete, download-url
class AttachmentRepository {
  final Dio _dio = ApiClient.instance;

  // ─── POST /attachments (Multipart) ────────────────────────────────────────
  Future<ApiResult<Map<String, dynamic>>> uploadAttachment({
    required String logEntryId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'logEntryId': logEntryId,
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final resp = await _dio.post(
        ApiEndpoints.attachments,
        data: formData,
        options: dio_lib.Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      if (resp.statusCode == 201) return ApiSuccess(resp.data);
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: resp.data?['message'] ?? 'Upload failed',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── POST /attachments/{id}/delete ────────────────────────────────────────
  Future<ApiResult<void>> deleteAttachment(String id) async {
    try {
      final resp = await _dio.post(ApiEndpoints.attachmentDelete(id));
      if (resp.statusCode == 204) return const ApiSuccess(null);
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: resp.data?['message'] ?? 'Delete failed',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── GET /attachments/{id}/download ──────────────────────────────────────
  Future<ApiResult<Map<String, dynamic>>> getDownloadUrl(String id) async {
    try {
      final resp = await _dio.get(ApiEndpoints.attachmentDownload(id));
      if (resp.statusCode == 200) return ApiSuccess(resp.data);
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: resp.data?['message'] ?? 'Failed',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }
}
