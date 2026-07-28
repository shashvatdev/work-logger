import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';
import '../../data/models/models.dart';

/// User repository — profile management + admin user operations
class UserRepository {
  final Dio _dio = ApiClient.instance;

  // ─── GET /users/me ────────────────────────────────────────────────────────
  Future<ApiResult<UserModel>> getMe() async {
    try {
      final resp = await _dio.get(ApiEndpoints.usersMe);
      if (resp.statusCode == 200) {
        return ApiSuccess(UserModel.fromJson(resp.data));
      }
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: resp.data?['message'] ?? 'Failed to get profile',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── PUT /users/me ────────────────────────────────────────────────────────
  Future<ApiResult<UserModel>> updateMe({
    required String name,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final body = <String, dynamic>{'name': name};
      if (currentPassword != null) body['currentPassword'] = currentPassword;
      if (newPassword != null) body['newPassword'] = newPassword;

      final resp = await _dio.post(ApiEndpoints.usersMeUpdate, data: body);
      if (resp.statusCode == 200) {
        return ApiSuccess(UserModel.fromJson(resp.data));
      }
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: resp.data?['message'] ?? 'Update failed',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── GET /users (Admin) ───────────────────────────────────────────────────
  Future<ApiResult<List<UserModel>>> getAllUsers({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.users,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      if (resp.statusCode == 200) {
        final list = (resp.data['users'] as List)
            .map((u) => UserModel.fromJson(u))
            .toList();
        return ApiSuccess(list);
      }
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: resp.data?['message'] ?? 'Failed to load users',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── POST /users (Admin) ──────────────────────────────────────────────────
  Future<ApiResult<UserModel>> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final resp = await _dio.post(ApiEndpoints.users, data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });
      if (resp.statusCode == 201) {
        return ApiSuccess(UserModel.fromJson(resp.data));
      }
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: resp.data?['message'] ?? 'Failed to create user',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── GET /users/{id} (Admin) ──────────────────────────────────────────────
  Future<ApiResult<UserModel>> getUserById(String id) async {
    try {
      final resp = await _dio.get(ApiEndpoints.userById(id));
      if (resp.statusCode == 200) return ApiSuccess(UserModel.fromJson(resp.data));
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: resp.data?['message'] ?? 'User not found',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── POST /users/{id}/update (Admin) ─────────────────────────────────────────
  Future<ApiResult<UserModel>> updateUser(
    String id, {
    required String name,
    required String role,
    required bool isActive,
  }) async {
    try {
      final resp = await _dio.post(ApiEndpoints.userUpdate(id), data: {
        'name': name,
        'role': role,
        'isActive': isActive,
      });
      if (resp.statusCode == 200) return ApiSuccess(UserModel.fromJson(resp.data));
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: resp.data?['message'] ?? 'Update failed',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── POST /users/{id}/delete (Admin) ──────────────────────────────────────────
  Future<ApiResult<void>> deleteUser(String id) async {
    try {
      final resp = await _dio.post(ApiEndpoints.userDelete(id));
      if (resp.statusCode == 204) return const ApiSuccess(null);
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: resp.data?['message'] ?? 'Delete failed',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── GET /users/{id}/today-status (Admin) ────────────────────────────────
  Future<ApiResult<Map<String, dynamic>>> getTodayStatus(String id) async {
    try {
      final resp = await _dio.get(ApiEndpoints.userTodayStatus(id));
      if (resp.statusCode == 200) return ApiSuccess(resp.data);
      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: resp.data?['message'] ?? 'Failed',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  // ─── GET /users/{id}/logs (Admin) ────────────────────────────────────────
  Future<ApiResult<Map<String, dynamic>>> getUserLogs(
    String id, {
    String? from,
    String? to,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      };
      final resp = await _dio.get(ApiEndpoints.userLogs(id),
          queryParameters: query);
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
