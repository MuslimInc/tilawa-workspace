import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit_v2/tilawa_ui_kit_v2.dart';

import 'golden_constraints.dart';
import 'preview_wrapper.dart';

void main() {
  group('v2 atoms', () {
    goldenTest(
      'TilawaBtn — variants',
      fileName: 'atoms/btn_variants',
      // `loading` scenario animates a spinner forever — settle would time out.
      pumpBeforeTest: pumpOnce,
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2AtomConstraints,
        children: [
          GoldenTestScenario(
            name: 'primary',
            child: V2PreviewWrapper(
              child: TilawaBtn(label: 'Resume reading', onPressed: () {}),
            ),
          ),
          GoldenTestScenario(
            name: 'primary · leading icon',
            child: V2PreviewWrapper(
              child: TilawaBtn(
                label: 'Download',
                leadingIcon: Icons.download,
                onPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'ghost',
            child: V2PreviewWrapper(
              child: TilawaBtn(
                label: 'Edit profile',
                variant: TilawaBtnVariant.ghost,
                onPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'quiet',
            child: V2PreviewWrapper(
              child: TilawaBtn(
                label: 'Skip',
                variant: TilawaBtnVariant.quiet,
                onPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'inverse · on emerald',
            child: V2PreviewWrapper(
              background: TilawaPalette.green700,
              child: TilawaBtn(
                label: 'Continue',
                variant: TilawaBtnVariant.inverse,
                onPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'sm size',
            child: V2PreviewWrapper(
              child: TilawaBtn(
                label: 'Small',
                size: TilawaBtnSize.sm,
                onPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'disabled',
            child: const V2PreviewWrapper(
              child: TilawaBtn(label: 'Disabled', onPressed: null),
            ),
          ),
          GoldenTestScenario(
            name: 'loading',
            child: V2PreviewWrapper(
              child: TilawaBtn(
                label: 'Loading',
                isLoading: true,
                onPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'expand · full width',
            child: V2PreviewWrapper(
              child: TilawaBtn(
                label: 'Sign in',
                expand: true,
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaIconBtn — variants & sizes',
      fileName: 'atoms/icon_btn_variants',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2AtomConstraints,
        children: [
          GoldenTestScenario(
            name: 'plain',
            child: V2PreviewWrapper(
              child: TilawaIconBtn(
                icon: Icons.bookmark_border,
                semanticLabel: 'Bookmark',
                onPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'ring',
            child: V2PreviewWrapper(
              child: TilawaIconBtn(
                icon: Icons.share_outlined,
                semanticLabel: 'Share',
                variant: TilawaIconBtnVariant.ring,
                onPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'solid · md',
            child: V2PreviewWrapper(
              child: TilawaIconBtn(
                icon: Icons.play_arrow,
                semanticLabel: 'Play',
                variant: TilawaIconBtnVariant.solid,
                onPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'solid · lg',
            child: V2PreviewWrapper(
              child: TilawaIconBtn(
                icon: Icons.play_arrow,
                semanticLabel: 'Play',
                variant: TilawaIconBtnVariant.solid,
                size: TilawaIconBtnSize.lg,
                onPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'inverse',
            child: V2PreviewWrapper(
              background: TilawaPalette.green700,
              child: TilawaIconBtn(
                icon: Icons.close,
                semanticLabel: 'Close',
                variant: TilawaIconBtnVariant.inverse,
                onPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'disabled',
            child: const V2PreviewWrapper(
              child: TilawaIconBtn(
                icon: Icons.bookmark_border,
                semanticLabel: 'Bookmark',
                onPressed: null,
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaAvatar — sizes',
      fileName: 'atoms/avatar_sizes',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2AtomConstraints,
        children: [
          GoldenTestScenario(
            name: 'md',
            child: const V2PreviewWrapper(
              child: TilawaAvatar(initials: 'MK'),
            ),
          ),
          GoldenTestScenario(
            name: 'lg',
            child: const V2PreviewWrapper(
              child: TilawaAvatar(initials: 'MK', size: TilawaAvatarSize.lg),
            ),
          ),
          GoldenTestScenario(
            name: 'xl',
            child: const V2PreviewWrapper(
              child: TilawaAvatar(initials: 'MK', size: TilawaAvatarSize.xl),
            ),
          ),
          GoldenTestScenario(
            name: 'no gold ring',
            child: const V2PreviewWrapper(
              child: TilawaAvatar(initials: 'MK', showGoldRing: false),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaTag — variants',
      fileName: 'atoms/tag_variants',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2AtomConstraints,
        children: [
          GoldenTestScenario(
            name: 'gold',
            child: const V2PreviewWrapper(child: TilawaTag(label: 'New')),
          ),
          GoldenTestScenario(
            name: 'quiet',
            child: const V2PreviewWrapper(
              child: TilawaTag(label: 'Hafs', variant: TilawaTagVariant.quiet),
            ),
          ),
          GoldenTestScenario(
            name: 'ghost',
            child: const V2PreviewWrapper(
              child: TilawaTag(label: 'Mecca', variant: TilawaTagVariant.ghost),
            ),
          ),
          GoldenTestScenario(
            name: 'gold · with icon',
            child: const V2PreviewWrapper(
              child: TilawaTag(label: 'New', leadingIcon: Icons.star),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaNumBadge — 8-point star',
      fileName: 'atoms/num_badge',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2AtomConstraints,
        children: [
          GoldenTestScenario(
            name: 'soft',
            child: const V2PreviewWrapper(child: TilawaNumBadge(number: 1)),
          ),
          GoldenTestScenario(
            name: 'gold',
            child: const V2PreviewWrapper(
              child: TilawaNumBadge(
                number: 36,
                variant: TilawaNumBadgeVariant.gold,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'solid',
            child: const V2PreviewWrapper(
              child: TilawaNumBadge(
                number: 114,
                variant: TilawaNumBadgeVariant.solid,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'soft · large',
            child: const V2PreviewWrapper(
              child: TilawaNumBadge(number: 7, size: 56),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaProgressBar — states',
      fileName: 'atoms/progress_bar',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2AtomConstraints,
        children: [
          GoldenTestScenario(
            name: 'empty',
            child: const V2PreviewWrapper(
              child: SizedBox(width: 200, child: TilawaProgressBar(value: 0)),
            ),
          ),
          GoldenTestScenario(
            name: 'mid',
            child: const V2PreviewWrapper(
              child: SizedBox(
                width: 200,
                child: TilawaProgressBar(value: 0.49),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'full',
            child: const V2PreviewWrapper(
              child: SizedBox(width: 200, child: TilawaProgressBar(value: 1)),
            ),
          ),
          GoldenTestScenario(
            name: 'with thumb',
            child: const V2PreviewWrapper(
              child: SizedBox(
                width: 200,
                child: TilawaProgressBar(value: 0.34, showThumb: true),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaProgressRing — states',
      fileName: 'atoms/progress_ring',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2AtomConstraints,
        children: [
          GoldenTestScenario(
            name: 'empty',
            child: V2PreviewWrapper(child: TilawaProgressRing(value: 0)),
          ),
          GoldenTestScenario(
            name: 'mid',
            child: V2PreviewWrapper(child: TilawaProgressRing(value: 0.49)),
          ),
          GoldenTestScenario(
            name: 'full · with label',
            child: V2PreviewWrapper(
              child: TilawaProgressRing(
                value: 1,
                child: const Text(
                  '100%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaToggle — on / off',
      fileName: 'atoms/toggle',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2AtomConstraints,
        children: [
          GoldenTestScenario(
            name: 'off',
            child: V2PreviewWrapper(
              child: TilawaToggle(value: false, onChanged: (_) {}),
            ),
          ),
          GoldenTestScenario(
            name: 'on',
            child: V2PreviewWrapper(
              child: TilawaToggle(value: true, onChanged: (_) {}),
            ),
          ),
          GoldenTestScenario(
            name: 'disabled',
            child: const V2PreviewWrapper(
              child: TilawaToggle(value: true, onChanged: null),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaSpinner, Skeleton, Dots, Divider',
      fileName: 'atoms/spinner_skeleton_dots_divider',
      // Spinner + Skeleton run infinite animations — pumpAndSettle never
      // returns. Pump once instead.
      pumpBeforeTest: pumpOnce,
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2AtomConstraints,
        children: [
          GoldenTestScenario(
            name: 'spinner',
            child: const V2PreviewWrapper(
              child: TilawaSpinner(color: TilawaPalette.green600),
            ),
          ),
          GoldenTestScenario(
            name: 'skeleton',
            child: const V2PreviewWrapper(
              child: TilawaSkeleton(width: 240, height: 16),
            ),
          ),
          GoldenTestScenario(
            name: 'dots · 4 · active 1',
            child: const V2PreviewWrapper(
              child: TilawaDots(count: 4, activeIndex: 1),
            ),
          ),
          GoldenTestScenario(
            name: 'divider',
            child: const V2PreviewWrapper(
              child: SizedBox(width: 320, child: TilawaDivider()),
            ),
          ),
          GoldenTestScenario(
            name: 'divider · inset from icon',
            child: const V2PreviewWrapper(
              child: SizedBox(
                width: 320,
                child: TilawaDivider(
                  inset: TilawaDividerInset.trailingFromIcon,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'TilawaField — states',
      fileName: 'atoms/field',
      builder: () => GoldenTestGroup(
        scenarioConstraints: kV2AtomConstraints,
        children: [
          GoldenTestScenario(
            name: 'idle',
            child: const V2PreviewWrapper(
              child: SizedBox(
                width: 320,
                child: TilawaField(
                  label: 'Email',
                  placeholder: 'you@example.com',
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'with leading icon · help',
            child: const V2PreviewWrapper(
              child: SizedBox(
                width: 320,
                child: TilawaField(
                  label: 'Search',
                  placeholder: 'Surah, ayah, reciter',
                  leadingIcon: Icons.search,
                  help: 'Tip: try “Mulk” or “55:13”',
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'error',
            child: V2PreviewWrapper(
              child: SizedBox(
                width: 320,
                child: TilawaField(
                  label: 'Email',
                  placeholder: 'you@example.com',
                  errorText: 'Please enter a valid email address.',
                  controller: TextEditingController(text: 'not-an-email'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
