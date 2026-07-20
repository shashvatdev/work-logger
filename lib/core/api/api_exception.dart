import 'package:dio/dio.dart';

/// Standardized API exception that maps Dio errors to meaningful messages.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  const ApiException({
    this.statusCode,
    required this.message,
    this.errors,
  });

  /// Parse from Dio error
  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    final data = response?.data;

    String message;
    Map<String, dynamic>? errors;

    if (data is Map<String, dynamic>) {
      message = data['message'] as String? ?? _fromType(e.type);
      errors = data['errors'] as Map<String, dynamic>?;
    } else {
      message = _fromType(e.type);
    }

    return ApiException(
      statusCode: response?.statusCode,
      message: message,
      errors: errors,
    );
  }

  static String _fromType(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. Check your network.';
      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond.';
      case DioExceptionType.sendTimeout:
        return 'Request timed out while sending.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      case DioExceptionType.badResponse:
        return 'Unexpected server response.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}

/// Generic result wrapper — avoids try/catch in every provider.
sealed class ApiResult<T> {
  const ApiResult();
}

final class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

final class ApiError<T> extends ApiResult<T> {
  final ApiException exception;
  const ApiError(this.exception);
}

/// Extension helpers
extension ApiResultExtensions<T> on ApiResult<T> {
  bool get isSuccess => this is ApiSuccess<T>;
  T get data => (this as ApiSuccess<T>).data;
  ApiException get error => (this as ApiError<T>).exception;
}
