class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

class NetworkException extends ApiException {
  NetworkException(super.message) : super(statusCode: 0);
}

class ServerException extends ApiException {
  ServerException(super.message, {super.statusCode});
}

class FileTooLargeException extends ApiException {
  FileTooLargeException(super.message) : super(statusCode: 413);
}

class JobNotFoundException extends ApiException {
  JobNotFoundException(super.message) : super(statusCode: 404);
}
