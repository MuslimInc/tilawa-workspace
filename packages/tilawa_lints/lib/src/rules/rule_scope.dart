bool isGeneratedDartFile(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.gen.dart') ||
    path.endsWith('.config.dart') ||
    path.endsWith('.mocks.dart');

bool isUiKitImplementation(String path) =>
    path.replaceAll(r'\', '/').contains('/packages/ui_kit/lib/');

bool isProductDartFile(String path) {
  final normalized = path.replaceAll(r'\', '/');
  if (isGeneratedDartFile(normalized) || isUiKitImplementation(normalized)) {
    return false;
  }
  return normalized.contains('/lib/') &&
      !normalized.contains('/packages/tilawa_lints/lib/') &&
      !normalized.contains('/packages/flex_color_scheme/lib/');
}
