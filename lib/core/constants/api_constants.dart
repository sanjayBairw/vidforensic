import 'dart:io';

class ApiConstants {
  // ✅ Production — Render Cloud Backend
  static const String productionUrl =
      'https://vidforensicback.onrender.com/api/v1';

  // Development fallbacks
  static const String localHostUrl = 'http://10.151.10.3:8000/api/v1';
  static const String androidEmulatorUrl = 'http://10.151.10.3:8000/api/v1';

  /// Set to true to use local dev server, false to use Render production
  static const bool useLocalDev = true;

  static String? _overrideBaseUrl;

  static String get localhostUrl => localHostUrl;
  static String get emulatorUrl => androidEmulatorUrl;

  static set baseUrl(String url) {
    _overrideBaseUrl = url;
  }

  // Dynamic Base URL selection
  static String get baseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }
    // Use local dev only when flag is set
    if (useLocalDev) {
      if (Platform.isAndroid) return androidEmulatorUrl;
      return localHostUrl;
    }
    // Default: Render production backend
    return productionUrl;
  }

  // Endpoints
  static const String health = '/health';
  static const String uploadVideo = '/videos/upload';

  static String jobAnalyze(String jobId) => '/videos/$jobId/analyze';
  static String jobStatus(String jobId) => '/videos/$jobId/status';
  static String jobResults(String jobId) => '/videos/$jobId/results';
  static String jobEvidence(String jobId) => '/videos/$jobId/evidence';
  static String jobReport(String jobId) => '/videos/$jobId/report';
  static String jobHealth(String jobId) => '/videos/$jobId/health';
  static String jobsHistory({int page = 1, int pageSize = 20}) =>
      '/jobs?page=$page&page_size=$pageSize';
  static String jobDetail(String jobId) => '/jobs/$jobId';
  static String deleteJob(String jobId) => '/jobs/$jobId';

  // Video Comparison Endpoints
  static const String comparisons = '/comparisons';
  static String comparisonStatus(String id) => '/comparisons/$id/status';
  static String comparisonResults(String id) => '/comparisons/$id/results';
  static String comparisonReport(String id) => '/comparisons/$id/report';
  static String comparisonEvidence(String id, String filename) =>
      '/comparisons/$id/evidence/$filename';
  static String comparisonVideo(String id, String target) =>
      '/comparisons/$id/video/$target';

  // Timeouts & Config
  static const Duration connectTimeout = Duration(
    seconds: 60,
  ); // longer for cold starts
  static const Duration receiveTimeout = Duration(seconds: 120);
  static const Duration sendTimeout = Duration(minutes: 10);
  static const Duration pollingInterval = Duration(seconds: 3);
}
