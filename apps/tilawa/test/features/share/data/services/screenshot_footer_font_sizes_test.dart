import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  test('footer label font sizes fall back when role fontSize is null', () {
    const textTheme = TextTheme(
      titleSmall: TextStyle(),
      bodySmall: TextStyle(),
    );
    final tokens = TilawaFooterBarTokens.defaults();

    final primary = tilawaResolveTextRole(
      textTheme,
      tokens.primaryLabelTextRole,
    ).fontSize ?? 14.0;
    final secondary = tilawaResolveTextRole(
      textTheme,
      tokens.secondaryLabelTextRole,
    ).fontSize ?? 12.0;

    expect(primary, 14.0);
    expect(secondary, 12.0);
  });
}
