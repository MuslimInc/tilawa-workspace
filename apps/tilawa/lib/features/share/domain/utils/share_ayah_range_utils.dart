import 'package:quran_qcf/quran_qcf.dart';

typedef ShareAyahRange = ({int fromAyah, int toAyah});

ShareAyahRange normalizeShareAyahRange({
  required int surahNumber,
  required int fromAyah,
  required int toAyah,
}) {
  final maxAyah = getVerseCount(surahNumber);
  final normalizedFromAyah = fromAyah.clamp(1, maxAyah);
  final normalizedToAyah = toAyah.clamp(normalizedFromAyah, maxAyah);

  return (fromAyah: normalizedFromAyah, toAyah: normalizedToAyah);
}

String? tryGetVerseQcfText(
  int surahNumber,
  int ayahNumber, {
  bool verseEndSymbol = false,
}) {
  try {
    return getVerseQCF(surahNumber, ayahNumber, verseEndSymbol: verseEndSymbol);
  } catch (_) {
    return null;
  }
}

String? tryGetVerseNumberQcfText(int surahNumber, int ayahNumber) {
  try {
    return getVerseNumberQCF(surahNumber, ayahNumber);
  } catch (_) {
    return null;
  }
}
