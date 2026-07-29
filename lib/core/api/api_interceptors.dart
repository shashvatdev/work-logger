import 'dart:convert';
import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'token_storage.dart';
import 'api_endpoints.dart';
import 'api_client.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Track It Logger Interceptor
///
/// Logs all HTTP requests and responses for debugging.
/// Format is compatible with Dart's `dart:developer` log
/// so it shows up cleanly in DevTools.
/// ─────────────────────────────────────────────────────────────────────────────
class TrackItLoggerInterceptor extends Interceptor {
  static const _tag = 'Track It API';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln('┌──────────────────────────────────────────────────────');
    buffer.writeln('│  ▶ REQUEST');
    buffer.writeln('│  ${options.method}  ${options.uri}');
    buffer.writeln('│');
    buffer.writeln('│  Headers:');
    options.headers.forEach((k, v) {
      // Mask token in logs for security
      final display = k == 'Authorization'
          ? 'Bearer ••••••${(v as String).substring((v).length - 6)}'
          : v;
      buffer.writeln('│    $k: $display');
    });
    if (options.data != null) {
      buffer.writeln('│');
      buffer.writeln('│  Body:');
      try {
        final pretty = const JsonEncoder.withIndent('  ')
            .convert(options.data is String
                ? jsonDecode(options.data)
                : options.data);
        for (final line in pretty.split('\n')) {
          buffer.writeln('│    $line');
        }
      } catch (_) {
        buffer.writeln('│    ${options.data}');
      }
    }
    buffer.writeln('└──────────────────────────────────────────────────────');
    dev.log(buffer.toString(), name: _tag);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln('┌──────────────────────────────────────────────────────');
    buffer.writeln('│  ✅ RESPONSE  [${response.statusCode}]');
    buffer.writeln('│  ${response.requestOptions.method}  ${response.requestOptions.uri}');
    buffer.writeln('│');
    buffer.writeln('│  Body:');
    try {
      final pretty = const JsonEncoder.withIndent('  ').convert(response.data);
      for (final line in pretty.split('\n')) {
        buffer.writeln('│    $line');
      }
    } catch (_) {
      buffer.writeln('│    ${response.data}');
    }
    buffer.writeln('└──────────────────────────────────────────────────────');
    dev.log(buffer.toString(), name: _tag);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln('┌──────────────────────────────────────────────────────');
    buffer.writeln('│  ❌ ERROR  [${err.response?.statusCode ?? 'NO STATUS'}]');
    buffer.writeln('│  ${err.requestOptions.method}  ${err.requestOptions.uri}');
    buffer.writeln('│');
    buffer.writeln('│  Type: ${err.type.name}');
    buffer.writeln('│  Message: ${err.message}');
    if (err.response?.data != null) {
      buffer.writeln('│');
      buffer.writeln('│  Error Body:');
      try {
        final pretty =
            const JsonEncoder.withIndent('  ').convert(err.response!.data);
        for (final line in pretty.split('\n')) {
          buffer.writeln('│    $line');
        }
      } catch (_) {
        buffer.writeln('│    ${err.response?.data}');
      }
    }
    buffer.writeln('└──────────────────────────────────────────────────────');
    dev.log(buffer.toString(), name: _tag, level: 900);
    handler.next(err);
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Auth Interceptor
///
/// 1. Attaches Bearer token to every request automatically.
/// 2. On 401 → silently refreshes the access token and retries once.
/// 3. On second 401 → clears tokens (user must re-login).
/// ─────────────────────────────────────────────────────────────────────────────
class AuthInterceptor extends QueuedInterceptorsWrapper {
  final Dio _dio;

  AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    // Only intercept 401 and skip if this is already a refresh call
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains(ApiEndpoints.refresh)) {
      try {
        final refreshToken = await TokenStorage.getRefreshToken();
        if (refreshToken == null) {
          await TokenStorage.clearAll();
          return handler.next(err);
        }

        // Attempt token refresh
        final refreshResp = await _dio.post(
          ApiEndpoints.refresh,
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Authorization': ''}),
        );

        final newAccess = refreshResp.data['accessToken'] as String;
        final newRefresh = refreshResp.data['refreshToken'] as String;
        await TokenStorage.saveTokens(
            accessToken: newAccess, refreshToken: newRefresh);

        // Retry original request with new token
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccess';
        final retryResp = await _dio.fetch(retryOptions);
        return handler.resolve(retryResp);
      } catch (_) {
        await TokenStorage.clearAll();
        ApiClient.onUnauthorized?.call();
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}
