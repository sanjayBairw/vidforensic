class ApiConstants {
  // Production Cloud Backend (Render)
  static const String renderUrl = 'https://vidforensicback.onrender.com/api/v1';

  // Local / LAN Backend Endpoints
  static const String localHostUrl = 'http://127.0.0.1:8000/api/v1';
  static const String lanServerUrl = 'http://192.168.1.196:8000/api/v1';

  static String? _overrideBaseUrl;

  static String get localhostUrl => localHostUrl;
  static String get emulatorUrl => lanServerUrl;
  static String get productionUrl => renderUrl;

  /// Helper to ensure the base URL always points cleanly to the API version route
  static String formatBaseUrl(String url) {
    var clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (!clean.endsWith('/api/v1')) {
      clean = '$clean/api/v1';
    }
    return clean;
  }

  static set baseUrl(String url) {
    _overrideBaseUrl = formatBaseUrl(url);
  }

  // Base URL selection (Render cloud URL by default for live deployment)
  static String get baseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }
    return renderUrl;
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
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 180);
  static const Duration sendTimeout = Duration(minutes: 10);
  static const Duration pollingInterval = Duration(seconds: 3);
}
