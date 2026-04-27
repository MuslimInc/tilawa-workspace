import 'package:quran_qcf/quran_qcf.dart';

void main() {
  final pageData = getPageData(385);
  print('Page 385 entries:');
  for (final entry in pageData) {
    print('Surah: ${entry.surah}, Start: ${entry.start}, End: ${entry.end}');
  }
}
