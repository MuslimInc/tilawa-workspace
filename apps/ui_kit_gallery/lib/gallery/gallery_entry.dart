import 'package:flutter/material.dart';

/// Component layer in the atomic design hierarchy.
enum GalleryCategory {
  atoms('Atoms'),
  molecules('Molecules'),
  organisms('Organisms');

  const GalleryCategory(this.label);

  final String label;
}

/// One browsable component demo in the gallery.
class GalleryEntry {
  const GalleryEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.builder,
    this.description,
  });

  final String id;
  final String name;
  final GalleryCategory category;
  final String? description;
  final WidgetBuilder builder;
}
