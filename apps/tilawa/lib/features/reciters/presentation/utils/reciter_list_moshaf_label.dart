import 'package:tilawa_core/entities/moshaf_entity.dart';

/// Breakpoint at which the letter index defaults to visible (tablets+).
const double kRecitersAlphabetDefaultVisibleBreakpoint = 400;

/// Compacts a full moshaf name for reciter list rows.
///
/// Strips the common `Rewayat` prefix and keeps the riwaya plus the last
/// style segment when hyphen-separated (e.g. Hafs + Mojawwad).
String compactMoshafName(String fullName) {
  final String trimmed = fullName.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }

  String name = trimmed;
  const String prefix = 'Rewayat ';
  if (name.startsWith(prefix)) {
    name = name.substring(prefix.length);
  }

  final List<String> parts = name
      .split(RegExp(r'\s*-\s*'))
      .map((String part) => part.trim())
      .where((String part) => part.isNotEmpty)
      .toList();

  if (parts.length <= 1) {
    return name;
  }

  final String riwaya = parts.first;
  final String style = parts.last;
  if (style == riwaya) {
    return riwaya;
  }

  return '$riwaya · $style';
}

/// Primary moshaf label for a reciter list row, with localized overflow.
String buildReciterListMoshafLabel({
  required List<MoshafEntity> moshaf,
  required String Function(int additionalCount) additionalMoshafLabel,
}) {
  if (moshaf.isEmpty) {
    return '';
  }

  final String primary = compactMoshafName(moshaf.first.name);
  final int additionalCount = moshaf.length - 1;
  if (additionalCount <= 0) {
    return primary;
  }

  return '$primary${additionalMoshafLabel(additionalCount)}';
}
