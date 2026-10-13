import 'package:intl/intl.dart';

class Formatters {
  static String formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes > 0) ? (bytes.toString().length - 1) ~/ 3 : 0;
    if (i >= suffixes.length) i = suffixes.length - 1;
    double num = bytes / (1 << (i * 10));
    return "${num.toStringAsFixed(decimals)} ${suffixes[i]}";
  }

  static String formatFileSize(int bytes, [int decimals = 2]) => formatBytes(bytes, decimals);

  static String formatTimestamp(double seconds) {
    if (seconds < 0) return "0.000s";
    final int minutes = seconds ~/ 60;
    final double remSec = seconds % 60;
    if (minutes > 0) {
      return "${minutes}m ${remSec.toStringAsFixed(3)}s";
    }
    return "${remSec.toStringAsFixed(3)}s";
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  static String formatISOString(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final DateTime dt = DateTime.parse(isoString);
      return DateFormat('MMM dd, yyyy • HH:mm:ss').format(dt.toLocal());
    } catch (_) {
      return isoString;
    }
  }
}
