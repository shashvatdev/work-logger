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

  /// Parse from non-2xx Response safely
  factory ApiException.fromResponse(int? statusCode, dynamic data, String fallbackMessage) {
    String message = fallbackMessage;
    Map<String, dynamic>? errors;

    if (data is Map<String, dynamic>) {
      if (data['message'] != null && data['message'].toString().isNotEmpty) {
        message = data['message'].toString();
      }
      if (data['errors'] is Map<String, dynamic>) {
        errors = data['errors'] as Map<String, dynamic>;
      }
    } else if (data is String && data.trim().isNotEmpty) {
      message = data;
    } else if (statusCode == 403) {
      message = 'Access denied. You do not have permission to perform this action.';
    } else if (statusCode == 401) {
      message = 'Unauthorized access.';
    } else if (statusCode == 404) {
      message = 'Requested resource not found.';
    }

    return ApiException(
      statusCode: statusCode,
      message: message,
      errors: errors,
    );
  }

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
