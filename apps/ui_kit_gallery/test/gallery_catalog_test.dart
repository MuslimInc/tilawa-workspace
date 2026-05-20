import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_gallery/gallery/gallery_catalog.dart';
import 'package:ui_kit_gallery/gallery/gallery_entry.dart';

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
  });
}
