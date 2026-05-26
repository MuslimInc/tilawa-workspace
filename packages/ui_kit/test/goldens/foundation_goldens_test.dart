import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilawa_ui_kit/src/foundation/app_colors.dart';
import 'package:tilawa_ui_kit/src/molecules/molecules.dart';

import '../../lib/src/previews/preview_wrapper.dart';
import 'golden_constraints.dart';

/// Frozen light neutral ramp for catalog chrome (DESIGN.md §2).
class _LightNeutralSwatchRow extends StatelessWidget {
  const _LightNeutralSwatchRow();

  @override
  Widget build(BuildContext context) {
    const swatches = <({String label, Color color})>[
      (label: 'surface', color: AppColors.lightBackground),
      (
        label: 'containerHigh',
        color: AppColors.lightSurfaceContainerHighBase,
      ),
      (label: 'hairline', color: AppColors.lightHairline),
      (label: 'ink', color: AppColors.lightInk),
    ];

    return Row(
      children: [
        for (final swatch in swatches)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: swatch.color,
                    border: Border.all(color: AppColors.lightHairline),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  swatch.label,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Foundation Golden Tests', () {
    goldenTest(
      'Light neutral ramp',
      fileName: 'foundation/light_neutral_ramp',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
        children: [
          GoldenTestScenario(
            name: 'Default primary',
            child: const TilawaPreviewWrapper(
              child: _LightNeutralSwatchRow(),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaCatalogAppBar',
      fileName: 'foundation/tilawa_catalog_app_bar',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kUiKitGoldenScenarioConstraints,
        children: [
          GoldenTestScenario(
            name: 'Title only',
            child: TilawaPreviewWrapper(
              padding: EdgeInsets.zero,
              child: Builder(
                builder: (context) => Scaffold(
                  appBar: TilawaCatalogAppBar.titleOnly(
                    context,
                    title: 'Reciters',
                  ),
                  body: const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Title and search',
            child: TilawaPreviewWrapper(
              padding: EdgeInsets.zero,
              child: Builder(
                builder: (context) {
                  return Scaffold(
                    appBar: TilawaCatalogAppBar(
                      preferredHeight:
                          TilawaAppBarConfig.catalogTitleAndSearchHeight(
                        context,
                      ),
                      title: 'Favorites',
                      bottomContent: TilawaSearchField(
                        hintText: 'Search',
                        onChanged: (_) {},
                      ),
                    ),
                    body: const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark title only',
            child: TilawaPreviewWrapper(
              isDark: true,
              padding: EdgeInsets.zero,
              child: Builder(
                builder: (context) => Scaffold(
                  appBar: TilawaCatalogAppBar.titleOnly(
                    context,
                    title: 'History',
                  ),
                  body: const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
