import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_gallery/gallery/gallery_catalog.dart';
import 'package:ui_kit_gallery/gallery/gallery_entry.dart';
import 'package:ui_kit_gallery/gallery/gallery_widget_manifest.dart';

void main() {
  test('gallery catalog has unique ids', () {
    final ids = galleryCatalog.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('gallery catalog covers all layers', () {
    final categories = galleryCatalog.map((e) => e.category).toSet();
    expect(categories.contains(GalleryCategory.atoms), isTrue);
    expect(categories.contains(GalleryCategory.molecules), isTrue);
    expect(categories.contains(GalleryCategory.organisms), isTrue);
    expect(categories.contains(GalleryCategory.foundation), isTrue);
  });

  test('manifest maps every demo widget to a gallery entry', () {
    final catalogIds = galleryCatalog.map((entry) => entry.id).toSet();

    for (final coverage in galleryWidgetManifest) {
      if (coverage.isSkipped) {
        continue;
      }
      expect(
        catalogIds,
        contains(coverage.galleryId),
        reason:
            '${coverage.symbol} expects gallery id '
            '"${coverage.galleryId}"',
      );
    }
  });

  test('every gallery entry is referenced by the manifest', () {
    final manifestGalleryIds = galleryWidgetManifest
        .where((coverage) => !coverage.isSkipped)
        .map((coverage) => coverage.galleryId!)
        .toSet();

    for (final entry in galleryCatalog) {
      expect(
        manifestGalleryIds,
        contains(entry.id),
        reason:
            'Add ${entry.name} (${entry.id}) to gallery_widget_manifest.dart',
      );
    }
  });

  test('manifest symbols are unique', () {
    final symbols = galleryWidgetManifest.map((e) => e.symbol).toList();
    expect(symbols.toSet().length, symbols.length);
  });
}
