import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'api_exceptions.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );
  }

  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await _dio.get(ApiConstants.health);
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> uploadVideo({
    required File file,
    required Function(int count, int total) onProgress,
  }) async {
    try {
      final String fileName = file.path.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post(
        ApiConstants.uploadVideo,
        data: formData,
        onSendProgress: onProgress,
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> startAnalysis(String jobId) async {
    try {
      final response = await _dio.post(ApiConstants.jobAnalyze(jobId));
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getStatus(String jobId) async {
    try {
      final response = await _dio.get(ApiConstants.jobStatus(jobId));
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getResults(String jobId) async {
    try {
      final response = await _dio.get(ApiConstants.jobResults(jobId));

      debugPrint('========== RAW API RESULTS ==========');
      debugPrint(response.data.toString());
      debugPrint('=====================================');

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getEvidence(String jobId) async {
    try {
      final response = await _dio.get(ApiConstants.jobEvidence(jobId));
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getJobHealth(String jobId) async {
    try {
      final response = await _dio.get(ApiConstants.jobHealth(jobId));
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> downloadReport(String jobId, String savePath) async {
    try {
      await _dio.download(
        ApiConstants.jobReport(jobId),
        savePath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          headers: {'Accept': 'application/pdf, */*'},
          receiveTimeout: const Duration(minutes: 3),
        ),
      );
      return savePath;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getJobsHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.jobsHistory(page: page, pageSize: pageSize),
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getJobDetail(String jobId) async {
    try {
      final response = await _dio.get(ApiConstants.jobDetail(jobId));
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> deleteJob(String jobId) async {
    try {
      final response = await _dio.delete(ApiConstants.deleteJob(jobId));
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return NetworkException(
        'Network connection timeout or server unreachable.',
      );
    }

    if (error.response != null) {
      final int statusCode = error.response!.statusCode ?? 500;
      final dynamic data = error.response!.data;
      String message = 'Server error occurred.';

      if (data is Map && data.containsKey('detail')) {
        message = data['detail'].toString();
      }

      if (statusCode == 413) {
        return FileTooLargeException(message);
      } else if (statusCode == 404) {
        return JobNotFoundException(message);
      }

      return ServerException(message, statusCode: statusCode);
    }

    return ApiException('An unexpected network error occurred.');
  }
}
