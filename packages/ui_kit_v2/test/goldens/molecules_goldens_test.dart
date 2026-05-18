import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit_v2/tilawa_ui_kit_v2.dart';

import 'golden_constraints.dart';
import 'preview_wrapper.dart';

void main() {
  group('v2 molecules', () {
    goldenTest(
      'TilawaSearchField',
      fileName: 'molecules/search_field',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2RowConstraints,
        children: [
          GoldenTestScenario(
            name: 'idle',
            child: const V2PreviewWrapper(
              child: SizedBox(width: 320, child: TilawaSearchField()),
            ),
          ),
          GoldenTestScenario(
            name: 'with text',
            child: V2PreviewWrapper(
              child: SizedBox(
                width: 320,
                child: TilawaSearchField(
                  controller: TextEditingController(text: 'Al-Mulk'),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaSurahRow',
      fileName: 'molecules/surah_row',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2RowConstraints,
        children: [
          GoldenTestScenario(
            name: 'default',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaSurahRow(
                number: 1,
                name: 'Al-Fatihah',
                arabicName: 'الفاتحة',
                meta: 'Meccan · 7 verses',
                onTap: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'active',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaSurahRow(
                number: 36,
                name: 'Ya-Sin',
                arabicName: 'يس',
                meta: 'Meccan · 83 verses',
                isActive: true,
                onTap: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'long name truncation',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaSurahRow(
                number: 114,
                name: 'An-Nas (The Mankind) — extended title test',
                arabicName: 'الناس',
                meta: 'Meccan · 6 verses',
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaReciterRow',
      fileName: 'molecules/reciter_row',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2RowConstraints,
        children: [
          GoldenTestScenario(
            name: 'default',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaReciterRow(
                name: 'Mishary Alafasy',
                meta: 'Hafs · Arabic',
                onTap: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'selected',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaReciterRow(
                name: 'Abdul Basit',
                meta: 'Hafs · Arabic',
                isSelected: true,
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaSectionHeader',
      fileName: 'molecules/section_header',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2RowConstraints,
        children: [
          GoldenTestScenario(
            name: 'loud · with action',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaSectionHeader(
                title: 'Continue listening',
                actionLabel: 'See all',
                onActionPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'loud · no action',
            child: const V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaSectionHeader(title: 'For you'),
            ),
          ),
          GoldenTestScenario(
            name: 'quiet (settings group)',
            child: const V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaSectionHeader(title: 'Preferences', quiet: true),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaEyebrow',
      fileName: 'molecules/eyebrow',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2AtomConstraints,
        children: [
          GoldenTestScenario(
            name: 'default',
            child: const V2PreviewWrapper(child: TilawaEyebrow('Continue')),
          ),
          GoldenTestScenario(
            name: 'on emerald',
            child: const V2PreviewWrapper(
              background: TilawaPalette.green700,
              child: TilawaEyebrow(
                'Now Reciting',
                color: TilawaPalette.gold300,
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaListItem',
      fileName: 'molecules/list_item',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2RowConstraints,
        children: [
          GoldenTestScenario(
            name: 'icon · chevron',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaListItem(
                icon: Icons.bookmark_border,
                label: 'Bookmarks',
                showChevron: true,
                onTap: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'with subtitle · value trailing',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaListItem(
                icon: Icons.speed,
                label: 'Playback speed',
                subtitle: 'Default tempo',
                trailing: const Text('1.0×'),
                onTap: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'toggle trailing',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaListItem(
                icon: Icons.dark_mode_outlined,
                label: 'Dark mode',
                trailing: TilawaToggle(value: true, onChanged: (_) {}),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'danger (sign out)',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: TilawaListItem(
                icon: Icons.logout,
                label: 'Sign out',
                tone: TilawaListItemTone.danger,
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaListGroup',
      fileName: 'molecules/list_group',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2OrganismConstraints,
        children: [
          GoldenTestScenario(
            name: 'library group',
            child: V2PreviewWrapper(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: TilawaListGroup(
                children: [
                  TilawaListItem(
                    icon: Icons.bookmark_border,
                    label: 'Bookmarks',
                    showChevron: true,
                    onTap: () {},
                  ),
                  TilawaListItem(
                    icon: Icons.download_outlined,
                    label: 'Downloads',
                    showChevron: true,
                    onTap: () {},
                  ),
                  TilawaListItem(
                    icon: Icons.history,
                    label: 'History',
                    showChevron: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaStatGroup',
      fileName: 'molecules/stat_group',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2RowConstraints,
        children: [
          GoldenTestScenario(
            name: 'profile stats',
            child: const V2PreviewWrapper(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: TilawaStatGroup(
                items: [
                  TilawaStatCard(value: '37', label: 'Surahs'),
                  TilawaStatCard(value: '14', unit: 'd', label: 'Streak'),
                  TilawaStatCard(value: '24', unit: 'h', label: 'Listened'),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaEmptyState',
      fileName: 'molecules/empty_state',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2OrganismConstraints,
        children: [
          GoldenTestScenario(
            name: 'no bookmarks',
            child: const V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: SizedBox(
                width: 360,
                child: TilawaEmptyState(
                  icon: Icons.bookmark_border,
                  title: 'No bookmarks yet',
                  body:
                      'Tap the bookmark icon on any verse to save it here for quick access.',
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'no downloads · with cta',
            child: V2PreviewWrapper(
              padding: EdgeInsets.zero,
              child: SizedBox(
                width: 360,
                child: TilawaEmptyState(
                  icon: Icons.download_outlined,
                  title: 'No downloads',
                  body:
                      'Save surahs for offline listening — wherever the connection isn’t.',
                  action: TilawaBtn(
                    label: 'Browse surahs',
                    variant: TilawaBtnVariant.ghost,
                    onPressed: () {},
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
