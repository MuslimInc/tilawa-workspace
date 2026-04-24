String? _resolvePageFontFamily(String path) {
  final String filename = path.split('/').last;

  // Strategy 1: Targeted QCF prefix (Handles QCF4001_X-Regular.woff, QCF4_163.woff, etc.)
  final RegExpMatch? qcfMatch = RegExp(r'QCF[34]_?(\d+)').firstMatch(filename);
  if (qcfMatch != null) {
    String pageNumStr = qcfMatch.group(1)!;
    // If it's a version-prefixed number like 4001, extract last 3
    if (pageNumStr.length > 3) {
      pageNumStr = pageNumStr.substring(pageNumStr.length - 3);
    }
    return 'QCF_P${pageNumStr.padLeft(3, '0')}';
  }

  // Strategy 2: Generic numeric before extension (Handles 163.woff, p001.ttf, etc.)
  final RegExpMatch? endMatch = RegExp(r'(\d+)\.[^.]+$').firstMatch(filename);
  if (endMatch != null) {
    String pageNumStr = endMatch.group(1)!;
    // If it's a version-prefixed number like 4001 without QCF prefix, extract last 3
    if (pageNumStr.length > 3) {
      pageNumStr = pageNumStr.substring(pageNumStr.length - 3);
    }
    return 'QCF_P${pageNumStr.padLeft(3, '0')}';
  }

  return null;
}

void main() {
  print('Result for QCF4_001.woff: ${_resolvePageFontFamily("QCF4_001.woff")}');
  print('Result for QCF4_1.woff: ${_resolvePageFontFamily("QCF4_1.woff")}');
  print('Result for 001.woff: ${_resolvePageFontFamily("001.woff")}');
  print('Result for QCF_P001.woff: ${_resolvePageFontFamily("QCF_P001.woff")}');
}
