import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_exception.dart';
import '../api/token_storage.dart';
import '../../data/models/models.dart';

/// Auth repository — login, refresh, logout
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
          refreshToken: data['refreshToken'] as String,
        );
        return ApiSuccess(data);
      }

      return ApiError(ApiException(
        statusCode: resp.statusCode,
        message: resp.data?['message'] ?? 'Login failed',
      ));
    } on DioException catch (e) {
      return ApiError(ApiException.fromDio(e));
    }
  }

  /// POST /auth/logout
  Future<ApiResult<void>> logout() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      await _dio.post(
        ApiEndpoints.logout,
        data: {'refreshToken': refreshToken},
      );
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
}
