import 'dart:math';

class FileSizeFormatter {
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) {
      return '0 B';
    }
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final int i = (log(bytes) / log(1024)).floor();
    if (i == 0) {
      return '$bytes B';
    }
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
