import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';
import '../models/office_model.dart';

class GeofenceRepository {
  final Dio _dio = ApiClient.instance;

  Future<ApiResult<List<OfficeModel>>> getOffices() async {
    try {
      final resp = await _dio.get(ApiEndpoints.geofence);
      if (resp.statusCode == 200) {
        final data = resp.data;
        List rawList = [];
        if (data is List) {
          rawList = data;
        } else if (data is Map) {
          rawList = data['zones'] ?? data['offices'] ?? data['data'] ?? [];
        }
        final list = rawList.map((o) => OfficeModel.fromJson(o as Map<String, dynamic>)).toList();
        return ApiSuccess(list);
      }
      return ApiError(ApiException.fromResponse(resp.statusCode, resp.data, 'Failed to get offices'));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  Future<ApiResult<OfficeModel>> createOffice({
    required String name,
    String? address,
    required double latitude,
    required double longitude,
    required double radiusInMeters,
  }) async {
    try {
      final resp = await _dio.post(ApiEndpoints.geofence, data: {
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'radiusInMeters': radiusInMeters,
      });
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        return ApiSuccess(OfficeModel.fromJson(resp.data));
      }
      return ApiError(ApiException.fromResponse(resp.statusCode, resp.data, 'Failed to create office'));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  Future<ApiResult<OfficeModel>> updateOffice(
    String id, {
    required String name,
    String? address,
    required double latitude,
    required double longitude,
    required double radiusInMeters,
  }) async {
    try {
      final resp = await _dio.post(ApiEndpoints.geofenceUpdate(id), data: {
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'radiusInMeters': radiusInMeters,
      });
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return ApiSuccess(OfficeModel.fromJson(resp.data));
      }
      return ApiError(ApiException.fromResponse(resp.statusCode, resp.data, 'Failed to update office'));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  Future<ApiResult<void>> deleteOffice(String id) async {
    try {
      final resp = await _dio.post(ApiEndpoints.geofenceDelete(id));
      if (resp.statusCode == 204 || resp.statusCode == 200) {
        return const ApiSuccess(null);
      }
      return ApiError(ApiException.fromResponse(resp.statusCode, resp.data, 'Failed to delete office'));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }
}
