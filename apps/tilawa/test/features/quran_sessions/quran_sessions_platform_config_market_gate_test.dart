import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_sessions/domain/entities/quran_sessions_platform_config.dart';

QuranSessionsPlatformConfig _config({
  bool enableForAllMarkets = false,
  List<String> enabledMarketCodes = const [],
}) => QuranSessionsPlatformConfig(
  quranSessionsEnabled: true,
  studentEntryEnabled: true,
  bookingEnabled: true,
  bookingMode: 'requiresTutorApproval',
  sessionMode: 'videoOnly',
  enabledCallProviders: const {'external', 'mock'},
  enableForAllMarkets: enableForAllMarkets,
  enabledMarketCodes: enabledMarketCodes,
);

void main() {
  group('QuranSessionsPlatformConfig.isMarketEnabled', () {
    test('Egypt enabled → available; other markets unavailable', () {
      final config = _config(enabledMarketCodes: const ['EG']);
      check(config.isMarketEnabled('EG')).isTrue();
      check(config.isMarketEnabled('eg')).isTrue(); // case-insensitive
      check(config.isMarketEnabled('SA')).isFalse();
      check(config.isMarketEnabled(null)).isFalse();
    });

    test('enableForAllMarkets → available for every market', () {
      final config = _config(enableForAllMarkets: true);
      check(config.isMarketEnabled('SA')).isTrue();
      check(config.isMarketEnabled('XX')).isTrue();
    });

    test('empty list blocks all markets', () {
      check(_config().isMarketEnabled('EG')).isFalse();
    });

    test('safeFallback fails closed', () {
      check(
        QuranSessionsPlatformConfig.safeFallback.isMarketEnabled('EG'),
      ).isFalse();
    });
  });

  group('fromJson / toJson', () {
    test('parses and normalizes the gate fields', () {
      final config = QuranSessionsPlatformConfig.fromJson(const {
        'quranSessionsEnabled': true,
        'enableForAllMarkets': false,
        'enabledMarketCodes': [' eg ', 'EG', 'sa'],
      });
      check(config.enableForAllMarkets).isFalse();
      check(config.enabledMarketCodes).deepEquals(const ['EG', 'SA']);
      check(config.isMarketEnabled('EG')).isTrue();
    });

    test('round-trips the gate fields', () {
      final config = _config(
        enableForAllMarkets: false,
        enabledMarketCodes: const ['EG'],
      );
      final restored = QuranSessionsPlatformConfig.fromJson(config.toJson());
      check(restored.enabledMarketCodes).deepEquals(const ['EG']);
      check(restored.enableForAllMarkets).isFalse();
    });

    test('defaults to a closed gate when fields are absent', () {
      final config = QuranSessionsPlatformConfig.fromJson(const {
        'quranSessionsEnabled': true,
      });
      check(config.enableForAllMarkets).isFalse();
      check(config.enabledMarketCodes).isEmpty();
    });
  });
}
