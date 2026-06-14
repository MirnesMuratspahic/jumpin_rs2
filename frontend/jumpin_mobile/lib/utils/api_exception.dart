import 'dart:convert';
import 'package:http/http.dart' as http;

/// Represents a failed API call. Thrown by providers so that the UI can tell
/// the difference between "the server returned an empty list" and an actual
/// error (401/403/5xx/network/parse). An empty list must only ever mean the
/// server successfully returned no items.
class ApiException implements Exception {
  /// HTTP status code, or null for network/parse failures.
  final int? statusCode;

  /// User-facing message safe to show in a SnackBar.
  final String message;

  ApiException(this.message, {this.statusCode});

  /// The user's session is no longer valid and they should re-authenticate.
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';

  /// Builds an [ApiException] from a non-2xx HTTP response, preferring the
  /// backend's own error message when present.
  factory ApiException.fromResponse(http.Response response) {
    final serverMessage = _extractServerMessage(response.body);

    switch (response.statusCode) {
      case 401:
        return ApiException(
          'Your session has expired. Please log in again.',
          statusCode: 401,
        );
      case 403:
        return ApiException(
          serverMessage ?? 'You do not have permission to perform this action.',
          statusCode: 403,
        );
      case 404:
        return ApiException(
          serverMessage ?? 'The requested item could not be found.',
          statusCode: 404,
        );
      case 400:
      case 409:
        return ApiException(
          serverMessage ?? 'The request could not be completed.',
          statusCode: response.statusCode,
        );
      default:
        if (response.statusCode >= 500) {
          return ApiException(
            'A server error occurred. Please try again later.',
            statusCode: response.statusCode,
          );
        }
        return ApiException(
          serverMessage ?? 'Something went wrong (${response.statusCode}).',
          statusCode: response.statusCode,
        );
    }
  }

  /// Wraps a network/parse error (no HTTP response available).
  factory ApiException.network([Object? error]) => ApiException(
        'Could not reach the server. Check your connection and try again.',
      );

  /// Pulls a human-readable message out of the backend error body.
  /// The API's ExceptionFilter returns `{ "errors": { "Key": ["msg"] } }`,
  /// and some endpoints return `{ "message": "..." }`.
  static String? _extractServerMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['message'] is String) {
          return decoded['message'] as String;
        }
        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          if (first is String) return first;
        }
      }
    } catch (_) {
      // Body wasn't JSON; fall through to the status-based default.
    }
    return null;
  }
}
