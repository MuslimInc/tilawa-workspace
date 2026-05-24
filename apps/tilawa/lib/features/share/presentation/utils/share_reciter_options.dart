import '../../domain/services/reciter_audio_catalog.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

class ShareReciterOption {
  const ShareReciterOption({required this.name, required this.serverUrl});

  final String name;
  final String serverUrl;
}

List<ShareReciterOption> buildShareReciterOptions({
  required List<ReciterEntity> reciters,
  required int surahNumber,
  String? selectedReciterName,
  String? selectedServerUrl,
}) {
  final String normalizedSelectedName = _normalizeReciterValue(
    selectedReciterName,
  );
  final String normalizedSelectedUrl = (selectedServerUrl ?? '').trim();
  final String formattedSurahNumber = surahNumber.toString().padLeft(3, '0');
  final List<ShareReciterOption> options = <ShareReciterOption>[];
  final Set<String> seenKeys = <String>{};

  for (final ReciterEntity reciter in reciters) {
    final List<MoshafEntity> matchingMoshafs = reciter.moshaf
        .where(
          (MoshafEntity moshaf) =>
              moshaf.server.trim().isNotEmpty &&
              _moshafSupportsSurah(moshaf, surahNumber) &&
              ReciterAudioCatalog.isReciterMapped(
                _buildSurahAudioUrl(moshaf.server, formattedSurahNumber),
              ),
        )
        .toList();
    if (matchingMoshafs.isEmpty) {
      continue;
    }

    MoshafEntity chosenMoshaf = matchingMoshafs.first;
    if (_normalizeReciterValue(reciter.name) == normalizedSelectedName &&
        normalizedSelectedUrl.isNotEmpty) {
      for (final MoshafEntity moshaf in matchingMoshafs) {
        final String server = moshaf.server.trim();
        if (normalizedSelectedUrl.contains(server) ||
            server.contains(normalizedSelectedUrl)) {
          chosenMoshaf = moshaf;
          break;
        }
      }
    }

    final ShareReciterOption option = ShareReciterOption(
      name: reciter.name.trim(),
      serverUrl: _buildSurahAudioUrl(chosenMoshaf.server, formattedSurahNumber),
    );
    final String dedupeKey =
        '${_normalizeReciterValue(option.name)}|${option.serverUrl.toLowerCase()}';
    if (seenKeys.add(dedupeKey)) {
      options.add(option);
    }
  }

  options.sort((ShareReciterOption a, ShareReciterOption b) {
    final bool aSelected = matchesShareReciterOption(
      a,
      selectedReciterName: selectedReciterName,
      selectedServerUrl: selectedServerUrl,
    );
    final bool bSelected = matchesShareReciterOption(
      b,
      selectedReciterName: selectedReciterName,
      selectedServerUrl: selectedServerUrl,
    );
    if (aSelected != bSelected) {
      return aSelected ? -1 : 1;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

  return options;
}

bool matchesShareReciterOption(
  ShareReciterOption option, {
  String? selectedReciterName,
  String? selectedServerUrl,
}) {
  final String normalizedSelectedName = _normalizeReciterValue(
    selectedReciterName,
  );
  final String normalizedOptionName = _normalizeReciterValue(option.name);
  final String normalizedSelectedUrl = (selectedServerUrl ?? '').trim();
  final String normalizedOptionUrl = option.serverUrl.trim();

  if (normalizedSelectedUrl.isNotEmpty &&
      (normalizedSelectedUrl == normalizedOptionUrl ||
          normalizedSelectedUrl.contains(normalizedOptionUrl) ||
          normalizedOptionUrl.contains(normalizedSelectedUrl))) {
    return true;
  }

  return normalizedSelectedName.isNotEmpty &&
      normalizedSelectedName == normalizedOptionName;
}

bool _moshafSupportsSurah(MoshafEntity moshaf, int surahNumber) {
  final String surahList = moshaf.surahList.trim();
  if (surahList.isEmpty) {
    return surahNumber <= moshaf.surahTotal;
  }

  final String target = surahNumber.toString();
  return surahList.split(',').map((value) => value.trim()).contains(target);
}

String _buildSurahAudioUrl(String server, String formattedSurahNumber) {
  final String normalizedServer = server.trim();
  if (normalizedServer.endsWith('/')) {
    return '$normalizedServer$formattedSurahNumber.mp3';
  }
  return '$normalizedServer/$formattedSurahNumber.mp3';
}

String _normalizeReciterValue(String? value) {
  return (value ?? '').trim().toLowerCase();
}
