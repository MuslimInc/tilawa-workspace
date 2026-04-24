import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/core/constants/quran_image_asset_constants.dart';

void main() {
  group('Quran asset configuration', () {
    test('centralised paths describe PNG lines and WebP header banner', () {
      expect(
        QuranImageAssetConstants.archiveLineImagePath(
          pageNumber: 1,
          oneBasedLineNumber: 1,
        ),
        'quran_images/1/1.png',
      );
      expect(
        QuranImageAssetConstants.surahHeaderBannerFileName,
        'sura_header_banner.webp',
      );
    });

    test('centralised remote URLs point at uploaded R2 objects', () {
      expect(
        QuranImageAssetConstants.remoteQuranImagesArchiveUrl,
        'https://pub-7f6f6686010343899ba5b2f0ac6cb7b3.r2.dev/'
        'quran_images.zip',
      );
      expect(
        QuranImageAssetConstants.remoteSurahHeaderBannerUrl,
        'https://pub-7f6f6686010343899ba5b2f0ac6cb7b3.r2.dev/'
        'sura_header_banner.webp',
      );
    });

    test('pubspec does not bundle remote Quran image assets', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(pubspec, isNot(contains('assets/images/sura_header_banner.webp')));
      expect(pubspec, isNot(contains('assets/images/sura_header_banner.png')));
      expect(pubspec, isNot(contains('assets/quran_images/1/')));
      expect(pubspec, isNot(contains('assets/quran_images/604/')));
      expect(pubspec, isNot(contains('assets/quran_images_webp/1/')));
    });
  });
}
