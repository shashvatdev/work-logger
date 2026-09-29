import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/token_storage.dart';


/// Auth repository — login, logout, password change
class AuthRepository {
  final Dio _dio = ApiClient.instance;

  /// POST /auth/login
  Future<ApiResult<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        await TokenStorage.saveTokens(
          accessToken: data['accessToken'] as String,
        );
        return ApiSuccess(data);
      }

      return ApiError(ApiException.fromResponse(
        resp.statusCode,
        resp.data,
        'Login failed',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  /// POST /auth/logout
  Future<ApiResult<void>> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
      await TokenStorage.clearAll();
      ApiClient.reset();
      return const ApiSuccess(null);
    } on DioException catch (e) {
      // Even if server call fails, clear local tokens
      await TokenStorage.clearAll();
      ApiClient.reset();
      return ApiError(ApiException.fromDio(e));
    }
  }

  /// POST /auth/change-password
  Future<ApiResult<void>> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.changePassword,
        data: {
          'email': email,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );

      if (resp.statusCode == 204 || resp.statusCode == 200) {
        return const ApiSuccess(null);
      }

      return ApiError(ApiException.fromResponse(
        resp.statusCode,
        resp.data,
        'Failed to change password.',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  /// POST /auth/forgot-password
  Future<ApiResult<void>> forgotPassword({
    required String email,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        return const ApiSuccess(null);
      }

      return ApiError(ApiException.fromResponse(
        resp.statusCode,
        resp.data,
        'Failed to send password reset OTP.',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  /// POST /auth/reset-password
  Future<ApiResult<void>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final resp = await _dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        },
      );

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        return const ApiSuccess(null);
      }

      return ApiError(ApiException.fromResponse(
        resp.statusCode,
        resp.data,
        'Failed to reset password.',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }
}

