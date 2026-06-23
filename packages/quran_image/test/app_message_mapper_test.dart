import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/l10n/quran_image_localizations_ar.dart';
import 'package:quran_image/l10n/quran_image_localizations_en.dart';
import 'package:quran_image/presentation/mappers/app_message_mapper.dart';

void main() {
  group('AppMessageL10n', () {
    test('localizes every app message variant in English', () {
      final l10n = QuranImageLocalizationsEn();

      expect(
        const PreparingQuranMessage().localize(l10n),
        'Preparing the Quran for you…',
      );
      expect(const QuranReadyMessage().localize(l10n), 'The Quran is ready.');
      expect(
        const CachePreparationFailedMessage().localize(l10n),
        'Something went wrong. Please try again.',
      );
      expect(
        const NetworkErrorMessage().localize(l10n),
        'Please check your internet connection and try again.',
      );
      expect(
        const UnexpectedErrorMessage().localize(l10n),
        'Something went wrong. Please try again.',
      );
      expect(
        const NavigationInitFailedMessage().localize(l10n),
        'Something went wrong. Please try again.',
      );
      expect(const AppTitleMessage().localize(l10n), 'AlQuran');
      expect(const RetryMessage().localize(l10n), 'Retry');
      expect(
        const PageIndicatorMessage(current: '12', total: '604').localize(l10n),
        'Page 12 of 604',
      );
      expect(const PageNumberMessage(12).localize(l10n), 'Page 12');
      expect(const JuzMessage(1).localize(l10n), 'Juz 1');
      expect(const HizbMessage(1).localize(l10n), 'Hizb 1');
    });

    test('localizes messages in Arabic', () {
      final l10n = QuranImageLocalizationsAr();

      expect(const AppTitleMessage().localize(l10n), 'القرآن');
      expect(const RetryMessage().localize(l10n), 'إعادة المحاولة');
      expect(
        const PageIndicatorMessage(current: '3', total: '604').localize(l10n),
        'صفحة 3 من 604',
      );
      expect(const PageNumberMessage(3).localize(l10n), 'صفحة 3');
      expect(const JuzMessage(1).localize(l10n), 'الجزء 1');
      expect(const HizbMessage(1).localize(l10n), 'الحزب 1');
    });
  });

  group('QuranImageCachePhaseMessage', () {
    test('maps cache phases to user-facing messages', () {
      expect(
        QuranImageCachePhase.checking.toAppMessage(),
        isA<PreparingQuranMessage>(),
      );
      expect(
        QuranImageCachePhase.downloadingImages.toAppMessage(),
        isA<PreparingQuranMessage>(),
      );
      expect(
        QuranImageCachePhase.downloadingHeader.toAppMessage(),
        isA<PreparingQuranMessage>(),
      );
      expect(
        QuranImageCachePhase.extracting.toAppMessage(),
        isA<PreparingQuranMessage>(),
      );
      expect(
        QuranImageCachePhase.ready.toAppMessage(),
        isA<QuranReadyMessage>(),
      );
      expect(
        QuranImageCachePhase.failed.toAppMessage(),
        isA<CachePreparationFailedMessage>(),
      );
    });
  });

  group('RawErrorAppMessageMapper', () {
    test('maps network errors to NetworkErrorMessage', () {
      const networkErrors = <String>[
        'SocketException: connection dropped',
        'Failed host lookup: cdn.example.com',
        'No address associated with hostname',
        'Connection refused by peer',
      ];

      for (final error in networkErrors) {
        expect(error.toAppMessage(), isA<NetworkErrorMessage>());
      }
    });

    test('maps non-network errors to UnexpectedErrorMessage', () {
      expect(
        'FormatException: bad response'.toAppMessage(),
        isA<UnexpectedErrorMessage>(),
      );
    });
  });
}
