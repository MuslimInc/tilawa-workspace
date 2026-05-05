import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilawa_ui_kit/src/atoms/tilawa_skeletonizer.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
import 'package:tilawa_ui_kit/src/foundation/density.dart';

import '../../lib/src/previews/preview_wrapper.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  AppTheme.useGoogleFonts = false;

  group('Skeletonizer Golden Tests', () {
    goldenTest(
      'TilawaSkeletonizer – enabled vs disabled',
      fileName: 'skeletonizer/enabled_disabled',
      pumpBeforeTest: (tester) async {
        // Settle shimmer animation to a deterministic frame
        await tester.pump(const Duration(milliseconds: 200));
      },
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Enabled',
            child: TilawaPreviewWrapper(
              child: SizedBox(
                width: 280,
                child: TilawaSkeletonizer(
                  child: Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: const Text('User Name'),
                      subtitle: const Text('user@example.com'),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Disabled',
            child: TilawaPreviewWrapper(
              child: SizedBox(
                width: 280,
                child: TilawaSkeletonizer(
                  enabled: false,
                  child: Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: const Text('User Name'),
                      subtitle: const Text('user@example.com'),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaSkeletonizer – text sizes preserved',
      fileName: 'skeletonizer/text_sizes',
      pumpBeforeTest: (tester) async {
        await tester.pump(const Duration(milliseconds: 200));
      },
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Heading + body + caption',
            child: TilawaPreviewWrapper(
              child: SizedBox(
                width: 300,
                child: TilawaSkeletonizer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Large Heading',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This is body text that spans multiple words to verify width preservation.',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Caption',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaSkeletonizer – containers and images',
      fileName: 'skeletonizer/containers',
      pumpBeforeTest: (tester) async {
        await tester.pump(const Duration(milliseconds: 200));
      },
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Card + Chip + CircleAvatar',
            child: TilawaPreviewWrapper(
              child: SizedBox(
                width: 280,
                child: TilawaSkeletonizer(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircleAvatar(radius: 24, child: Text('AB')),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Card Title',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Chip(
                                  label: const Text('Active'),
                                  backgroundColor: Colors.green.shade100,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaSkeletonizer – RTL',
      fileName: 'skeletonizer/rtl',
      pumpBeforeTest: (tester) async {
        await tester.pump(const Duration(milliseconds: 200));
      },
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Arabic text',
            child: TilawaPreviewWrapper(
              isRTL: true,
              child: SizedBox(
                width: 280,
                child: TilawaSkeletonizer(
                  child: Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: const Text('اسم المستخدم'),
                      subtitle: const Text('user@example.com'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaSkeletonizer – dark theme',
      fileName: 'skeletonizer/dark',
      pumpBeforeTest: (tester) async {
        await tester.pump(const Duration(milliseconds: 200));
      },
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Dark enabled',
            child: TilawaPreviewWrapper(
              isDark: true,
              child: SizedBox(
                width: 280,
                child: TilawaSkeletonizer(
                  child: Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: const Text('User Name'),
                      subtitle: const Text('user@example.com'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaSliverSkeletonizer – column equivalent',
      fileName: 'skeletonizer/sliver_equivalent',
      pumpBeforeTest: (tester) async {
        await tester.pump(const Duration(milliseconds: 200));
      },
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'ListTile column',
            child: TilawaPreviewWrapper(
              child: SizedBox(
                width: 280,
                child: TilawaSkeletonizer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const CircleAvatar(child: Text('1')),
                        title: const Text('Item 1'),
                        subtitle: const Text('Subtitle 1'),
                      ),
                      ListTile(
                        leading: const CircleAvatar(child: Text('2')),
                        title: const Text('Item 2'),
                        subtitle: const Text('Subtitle 2'),
                      ),
                      ListTile(
                        leading: const CircleAvatar(child: Text('3')),
                        title: const Text('Item 3'),
                        subtitle: const Text('Subtitle 3'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaSkeletonizer – ignore pointers',
      fileName: 'skeletonizer/ignore_pointers',
      pumpBeforeTest: (tester) async {
        await tester.pump(const Duration(milliseconds: 200));
      },
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Buttons disabled when enabled=true',
            child: TilawaPreviewWrapper(
              child: SizedBox(
                width: 280,
                child: TilawaSkeletonizer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Click Me'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Text Button'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Buttons active when enabled=false',
            child: TilawaPreviewWrapper(
              child: SizedBox(
                width: 280,
                child: TilawaSkeletonizer(
                  enabled: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Click Me'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Text Button'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaSkeletonizer – compact density',
      fileName: 'skeletonizer/compact',
      pumpBeforeTest: (tester) async {
        await tester.pump(const Duration(milliseconds: 200));
      },
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Compact density',
            child: TilawaPreviewWrapper(
              density: TilawaDensity.compact,
              child: SizedBox(
                width: 280,
                child: TilawaSkeletonizer(
                  child: Card(
                    child: ListTile(
                      dense: true,
                      leading: const CircleAvatar(
                        radius: 16,
                        child: Icon(Icons.person, size: 16),
                      ),
                      title: const Text('Compact Item'),
                      subtitle: const Text('Compact subtitle'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
