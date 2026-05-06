// The test for the FlexHighlightSplash.splashFactory is copied from
// Flutter repo and pretty identical to the test for InkSplash.
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flex_color_scheme/src/flex_instant_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('InkWell with NoSplash.splashFactory paints nothing AND '
      'InkWell FlexHighlightSplash paints one Circle quickly.', (
    WidgetTester tester,
  ) async {
    Widget buildFrame({InteractiveInkFeatureFactory? splashFactory}) {
      return MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Scaffold(
          body: Center(
            child: Material(
              child: InkWell(
                splashFactory: splashFactory,
                onTap: () {},
                child: const Text('test'),
              ),
            ),
          ),
        ),
      );
    }

    // NoSplash.splashFactory, no splash circles drawn
    await tester.pumpWidget(buildFrame(splashFactory: NoSplash.splashFactory));
    {
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('test')),
      );
      final MaterialInkController material = Material.of(
        tester.element(find.text('test')),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(material, paintsExactlyCountTimes(#drawCircle, 0));
      await gesture.up();
      await tester.pumpAndSettle();
    }

    // FlexHighlightSplash.splashFactory, one splash circle drawn quickly.
    await tester.pumpWidget(
      buildFrame(splashFactory: FlexInstantSplash.splashFactory),
    );
    {
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('test')),
      );
      final MaterialInkController material = Material.of(
        tester.element(find.text('test')),
      );
      await tester.pump(const Duration(milliseconds: 1));
      expect(material, paintsExactlyCountTimes(#drawCircle, 1));
      await gesture.up();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('InkResponse with FlexHighlightSplash uses rect callback '
      'for contained ink radius.', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Scaffold(
          body: Center(
            child: Material(
              child: _RectCallbackInkResponse(
                onTap: () {},
                splashFactory: FlexInstantSplash.splashFactory,
                child: const SizedBox(width: 72, height: 48),
              ),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(_RectCallbackInkResponse)),
    );
    final MaterialInkController material = Material.of(
      tester.element(find.byType(_RectCallbackInkResponse)),
    );
    await tester.pump(const Duration(milliseconds: 1));
    expect(material, paintsExactlyCountTimes(#drawCircle, 2));
    await gesture.up();
    await tester.pumpAndSettle();
  });
}

class _RectCallbackInkResponse extends InkResponse {
  const _RectCallbackInkResponse({
    required super.onTap,
    required super.splashFactory,
    required super.child,
  }) : super(containedInkWell: true);

  @override
  RectCallback? getRectCallback(RenderBox referenceBox) {
    return () => const Rect.fromLTWH(0, 0, 24, 24);
  }
}
