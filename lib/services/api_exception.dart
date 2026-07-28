/// Thrown by [ApiClient] whenever the backend returns a non-2xx response,
/// or the request fails for network reasons.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;

  /// Tries to pull the friendliest possible message out of a DRF style
  /// error payload, e.g. {"email": ["This field is required."]} or
  /// {"detail": "Not found."}.
  factory ApiException.fromBody(dynamic body, {int? statusCode}) {
    if (body is Map<String, dynamic>) {
      if (body['detail'] is String) {
        return ApiException(body['detail'], statusCode: statusCode, errors: body);
      }
      final firstKey = body.keys.isNotEmpty ? body.keys.first : null;
      if (firstKey != null) {
        final value = body[firstKey];
        String msg;
        if (value is List && value.isNotEmpty) {
          msg = value.first.toString();
        } else {
          msg = value.toString();
        }
        return ApiException(msg, statusCode: statusCode, errors: body);
      }
    }
    return ApiException('Something went wrong. Please try again.', statusCode: statusCode);
  }
}
