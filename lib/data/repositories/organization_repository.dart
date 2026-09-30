import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';
import '../models/organization_model.dart';

class OrganizationRepository {
  final Dio _dio = ApiClient.instance;

  /// GET /organizations
  Future<ApiResult<List<OrganizationModel>>> getOrganizations() async {
    try {
      final resp = await _dio.get(ApiEndpoints.organizations);
      if (resp.statusCode == 200) {
        final dynamic data = resp.data;
        List rawList = [];
        if (data is List) {
          rawList = data;
        } else if (data is Map && data['organizations'] is List) {
          rawList = data['organizations'] as List;
        } else if (data is Map && data['data'] is List) {
          rawList = data['data'] as List;
        }
        final list = rawList
            .map((item) => OrganizationModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return ApiSuccess(list);
      }
      return ApiError(ApiException.fromResponse(
        resp.statusCode,
        resp.data,
        'Failed to load organizations',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  /// POST /organizations
  Future<ApiResult<dynamic>> createOrganization(CreateOrganizationRequest request) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.organizations,
        data: request.toJson(),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return ApiSuccess(resp.data);
      }
      return ApiError(ApiException.fromResponse(
        resp.statusCode,
        resp.data,
        'Failed to create organization',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }
}
