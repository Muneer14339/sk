// Custom exceptions for the application

class ServerException implements Exception {
  final String message;
  final int statusCode;

  ServerException(this.message, {this.statusCode = 500});

  @override
  String toString() => 'ServerException: $message (Status Code: $statusCode)';
}

class CacheException implements Exception {
  final String message;

  CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;

  ValidationException(this.message, {this.errors});

  @override
  String toString() => 'ValidationException: $message';
}

class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException([this.message = 'Unauthorized']);

  @override
  String toString() => 'UnauthorizedException: $message';
}

class NotFoundException implements Exception {
  final String message;

  NotFoundException([this.message = 'Not Found']);

  @override
  String toString() => 'NotFoundException: $message';
}

class SimpleException implements Exception {
  final String message;

  SimpleException(this.message);

  @override
  String toString() => message;
}
