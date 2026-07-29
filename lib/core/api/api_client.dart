import 'package:dio/dio.dart';
import 'api_interceptors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ApiClient — single configured Dio instance for the entire app.
///
/// Change [baseUrl] to point to your backend.
/// ─────────────────────────────────────────────────────────────────────────────
class ApiClient {
  ApiClient._();

  // ── Base URL ─────────────────────────────────────────────────────────────────
  // Change this to your deployed backend URL when going to production.
  static const String baseUrl = 'https://worktracker.addonshareware.com/api/v1';
  // static const String baseUrl = 'http://192.168.1.25:5289/api/v1';


  static void Function()? onUnauthorized;

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _create();
    return _instance!;
  }

  static Dio _create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Treat 4xx/5xx as errors (not just 4xx)
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Order matters: Auth first (adds token), Logger second (logs full request)
    dio.interceptors.addAll([
      AuthInterceptor(dio),
      TrackItLoggerInterceptor(),
    ]);

    return dio;
  }

  /// Reset the instance (e.g. after logout or base URL change)
  static void reset() => _instance = null;
}
