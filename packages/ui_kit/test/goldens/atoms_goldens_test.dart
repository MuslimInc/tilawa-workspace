import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilawa_ui_kit/src/atoms/atoms.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';

import '../../lib/src/previews/preview_wrapper.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  AppTheme.useGoogleFonts = false;

  group('Atoms Golden Tests', () {
    goldenTest(
      'TilawaCard',
      fileName: 'atoms/tilawa_card',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Theme',
            child: const TilawaPreviewWrapper(
              child: TilawaCard(child: Text('Card Content')),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Theme',
            child: const TilawaPreviewWrapper(
              isDark: true,
              child: TilawaCard(child: Text('Dark Card')),
            ),
          ),
          GoldenTestScenario(
            name: 'RTL / Arabic',
            child: const TilawaPreviewWrapper(
              isRTL: true,
              child: TilawaCard(child: Text('بطاقة بنمط عربي')),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaIconBox',
      fileName: 'atoms/tilawa_icon_box',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Default',
            child: const TilawaPreviewWrapper(
              child: TilawaIconBox(icon: Icons.bookmark_rounded),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaIconToggle',
      fileName: 'atoms/tilawa_icon_toggle',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Off',
            child: TilawaPreviewWrapper(
              child: TilawaIconToggle(
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications,
                value: false,
                onChanged: (_) {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'On',
            child: TilawaPreviewWrapper(
              child: TilawaIconToggle(
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications,
                value: true,
                onChanged: (_) {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark on',
            child: TilawaPreviewWrapper(
              isDark: true,
              child: TilawaIconToggle(
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications,
                value: true,
                onChanged: (_) {},
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaEmptyState',
      fileName: 'atoms/tilawa_empty_state',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Default',
            child: TilawaPreviewWrapper(
              child: TilawaEmptyState(
                icon: Icons.inbox_outlined,
                title: 'No Data',
                subtitle: 'Add something to get started.',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Scale 1.5',
            child: TilawaPreviewWrapper(
              textScale: 1.5,
              child: TilawaEmptyState(
                icon: Icons.inbox_outlined,
                title: 'Scaled Text',
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaLoadingIndicator',
      fileName: 'atoms/tilawa_loading_indicator',
      pumpBeforeTest: (tester) async {
        // Deterministic fixed-time pump for a stable captured frame.
        await tester.pump(const Duration(milliseconds: 16));
      },
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Default',
            child: const TilawaPreviewWrapper(child: TilawaLoadingIndicator()),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaDivider',
      fileName: 'atoms/tilawa_divider',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Default',
            child: const TilawaPreviewWrapper(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Text Above'),
                  TilawaDivider(),
                  Text('Text Below'),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaSectionTitle',
      fileName: 'atoms/tilawa_section_title',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light',
            child: const TilawaPreviewWrapper(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TilawaSectionTitle(title: 'Section title'),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark',
            child: const TilawaPreviewWrapper(
              isDark: true,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TilawaSectionTitle(title: 'Section title'),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'RTL Arabic',
            child: const TilawaPreviewWrapper(
              isRTL: true,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TilawaSectionTitle(title: 'عنوان القسم'),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaSheetHandle',
      fileName: 'atoms/tilawa_sheet_handle',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light',
            child: const TilawaPreviewWrapper(
              child: SizedBox(width: 220, child: TilawaSheetHandle()),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark',
            child: const TilawaPreviewWrapper(
              isDark: true,
              child: SizedBox(width: 220, child: TilawaSheetHandle()),
            ),
          ),
        ],
      ),
    );
  });

  group('Button Golden Tests', () {
    goldenTest(
      'TilawaButton - Variants',
      fileName: 'atoms/tilawa_button_variants',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Primary',
            child: const TilawaPreviewWrapper(
              child: TilawaButton(text: 'Primary Button'),
            ),
          ),
          GoldenTestScenario(
            name: 'Secondary',
            child: const TilawaPreviewWrapper(
              child: TilawaButton(
                text: 'Secondary Button',
                variant: TilawaButtonVariant.secondary,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Outline',
            child: const TilawaPreviewWrapper(
              child: TilawaButton(
                text: 'Outline Button',
                variant: TilawaButtonVariant.outline,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Ghost',
            child: const TilawaPreviewWrapper(
              child: TilawaButton(
                text: 'Ghost Button',
                variant: TilawaButtonVariant.ghost,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Danger',
            child: const TilawaPreviewWrapper(
              child: TilawaButton(
                text: 'Danger Button',
                variant: TilawaButtonVariant.danger,
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaButton - States & Icons',
      fileName: 'atoms/tilawa_button_states',
      pumpBeforeTest: (tester) async {
        await tester.pump(const Duration(milliseconds: 100));
      },
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Disabled',
            child: const TilawaPreviewWrapper(
              child: TilawaButton(text: 'Disabled Button', onPressed: null),
            ),
          ),
          GoldenTestScenario(
            name: 'Loading',
            child: const TilawaPreviewWrapper(
              child: TilawaButton(text: 'Loading Button', isLoading: true),
            ),
          ),
          GoldenTestScenario(
            name: 'Leading Icon',
            child: const TilawaPreviewWrapper(
              child: TilawaButton(
                text: 'Search',
                leadingIcon: Icon(Icons.search),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Trailing Icon',
            child: const TilawaPreviewWrapper(
              child: TilawaButton(
                text: 'Next',
                trailingIcon: Icon(Icons.arrow_forward),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Full Width',
            child: const TilawaPreviewWrapper(
              child: TilawaButton(text: 'Full Width', isFullWidth: true),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaButton - Environment',
      fileName: 'atoms/tilawa_button_env',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Dark Mode - Primary',
            child: const TilawaPreviewWrapper(
              isDark: true,
              child: TilawaButton(text: 'Dark Primary'),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode - Outline',
            child: const TilawaPreviewWrapper(
              isDark: true,
              child: TilawaButton(
                text: 'Dark Outline',
                variant: TilawaButtonVariant.outline,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'RTL / Arabic',
            child: const TilawaPreviewWrapper(
              isRTL: true,
              child: TilawaButton(
                text: 'زر مع أيقونة',
                leadingIcon: Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  });

  group('TilawaTextField Goldens', () {
    goldenTest(
      'tilawa_text_field_variants',
      fileName: 'atoms/tilawa_text_field_variants',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Default',
            child: const TilawaPreviewWrapper(
              child: TilawaTextField(label: 'Label', hintText: 'Hint text'),
            ),
          ),
          GoldenTestScenario(
            name: 'Error',
            child: const TilawaPreviewWrapper(
              child: TilawaTextField(
                label: 'Label',
                errorText: 'Error message',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Disabled',
            child: const TilawaPreviewWrapper(
              child: TilawaTextField(
                label: 'Label',
                enabled: false,
                initialValue: 'Disabled text',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Password',
            child: const TilawaPreviewWrapper(
              child: TilawaTextField(
                label: 'Password',
                isPassword: true,
                initialValue: 'secret',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Search (Prefix Icon)',
            child: const TilawaPreviewWrapper(
              child: TilawaTextField(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'RTL Arabic',
            child: const TilawaPreviewWrapper(
              isRTL: true,
              child: TilawaTextField(
                label: 'الاسم',
                hintText: 'أدخل الاسم',
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Max Length Hidden Counter',
            child: const TilawaPreviewWrapper(
              child: TilawaTextField(
                hintText: 'Max 20 chars',
                maxLength: 20,
                initialValue: 'Hello',
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'tilawa_text_field_env',
      fileName: 'atoms/tilawa_text_field_env',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Dark Mode',
            child: const TilawaPreviewWrapper(
              isDark: true,
              child: TilawaTextField(
                label: 'Dark Mode Label',
                hintText: 'Dark mode hint',
              ),
            ),
          ),
        ],
      ),
    );
  });
}
