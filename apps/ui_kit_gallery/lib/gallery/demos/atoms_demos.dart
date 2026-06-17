import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'demo_helpers.dart';

/// Atom-layer component demos.
abstract final class AtomsDemos {
  static Widget card(BuildContext context) {
    return GalleryDemoFrame(
      child: gallerySection('Default', [
        const TilawaCard(child: Text('Card content')),
        const SizedBox(height: 16),
        TilawaCard(
          onTap: () {},
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            'Tappable card',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ]),
    );
  }

  static Widget button(BuildContext context) {
    return GalleryDemoFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          gallerySection('Variants', [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                TilawaButton(text: 'Primary', onPressed: () {}),
                TilawaButton(
                  text: 'Secondary',
                  variant: TilawaButtonVariant.secondary,
                  onPressed: () {},
                ),
                TilawaButton(
                  text: 'Outline',
                  variant: TilawaButtonVariant.outline,
                  onPressed: () {},
                ),
                TilawaButton(
                  text: 'Ghost',
                  variant: TilawaButtonVariant.ghost,
                  onPressed: () {},
                ),
                TilawaButton(
                  text: 'Danger',
                  variant: TilawaButtonVariant.danger,
                  onPressed: () {},
                ),
              ],
            ),
          ]),
          const SizedBox(height: 24),
          gallerySection('States', [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                const TilawaButton(text: 'Disabled', onPressed: null),
                TilawaButton(
                  text: 'Loading',
                  isLoading: true,
                  onPressed: () {},
                ),
              ],
            ),
          ]),
          const SizedBox(height: 24),
          gallerySection('Sizes', [
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TilawaButton(
                  text: 'Small',
                  size: TilawaButtonSize.small,
                  onPressed: () {},
                ),
                TilawaButton(
                  text: 'Medium',
                  size: TilawaButtonSize.medium,
                  onPressed: () {},
                ),
                TilawaButton(
                  text: 'Large',
                  size: TilawaButtonSize.large,
                  onPressed: () {},
                ),
              ],
            ),
          ]),
        ],
      ),
    );
  }

  static Widget divider(BuildContext context) {
    return const GalleryDemoFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Text('Above'), TilawaDivider(), Text('Below')],
      ),
    );
  }

  static Widget emptyState(BuildContext context) {
    return GalleryDemoFrame(
      child: TilawaEmptyState(
        icon: Icons.inbox_outlined,
        title: 'Nothing here yet',
        subtitle: 'New items will show up here once you add them.',
        action: TilawaButton(
          text: 'Add item',
          leadingIcon: const Icon(Icons.add),
          onPressed: () {},
        ),
      ),
    );
  }

  static Widget errorState(BuildContext context) {
    return GalleryDemoFrame(
      child: TilawaErrorState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load',
        subtitle: 'Check your connection and try again.',
        retryLabel: 'Retry',
        onRetry: () {},
      ),
    );
  }

  static Widget illustratedState(BuildContext context) {
    return GalleryDemoFrame(
      child: TilawaIllustratedState(
        title: 'Unlock premium reciters',
        subtitle: 'Subscribe to access the full catalog.',
        icon: Icons.workspace_premium_outlined,
        primaryAction: TilawaButton(text: 'Upgrade', onPressed: () {}),
        secondaryAction: TextButton(
          onPressed: () {},
          child: const Text('Maybe later'),
        ),
      ),
    );
  }

  static Widget iconBox(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GalleryDemoFrame(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const TilawaIconBox(icon: Icons.bookmark_rounded),
          TilawaIconBox(
            icon: Icons.favorite_rounded,
            backgroundColor: scheme.primaryContainer,
            iconColor: scheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }

  static Widget iconToggle(BuildContext context) {
    return GalleryDemoFrame(
      child: Wrap(
        spacing: 16,
        children: [
          TilawaIconToggle(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications,
            value: false,
            onChanged: (_) {},
          ),
          TilawaIconToggle(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications,
            value: true,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }

  static Widget loadingIndicator(BuildContext context) {
    return const GalleryDemoFrame(
      child: Wrap(
        spacing: 24,
        children: [
          TilawaLoadingIndicator(semanticsLabel: 'Loading'),
          TilawaLoadingIndicator(strokeWidth: 2),
        ],
      ),
    );
  }

  static Widget stateVisual(BuildContext context) {
    return GalleryDemoFrame(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          for (final tone in TilawaStateVisualTone.values)
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                TilawaStateVisual(
                  icon: Icons.inbox_outlined,
                  tone: tone,
                ),
                Text(tone.name),
              ],
            ),
        ],
      ),
    );
  }

  static Widget sectionTitle(BuildContext context) {
    return GalleryDemoFrame(
      alignment: Alignment.centerLeft,
      child: const TilawaSectionTitle(title: 'Section title'),
    );
  }

  static Widget sheetHandle(BuildContext context) {
    return GalleryDemoFrame(
      child: SizedBox(
        width: 280,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const TilawaSheetHandle(),
        ),
      ),
    );
  }

  static Widget checkbox(BuildContext context) {
    return GalleryDemoFrame(
      child: _CheckboxDemo(),
    );
  }

  static Widget googleSignInButton(BuildContext context) {
    return GalleryDemoFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          gallerySection('Appearances', [
            const TilawaGoogleSignInButton(
              label: 'Sign in with Google',
              appearance: GoogleSignInButtonAppearance.light,
            ),
            const SizedBox(height: 12),
            const TilawaGoogleSignInButton(
              label: 'Sign in with Google',
              appearance: GoogleSignInButtonAppearance.dark,
            ),
            const SizedBox(height: 12),
            const TilawaGoogleSignInButton(
              label: 'Sign in with Google',
              appearance: GoogleSignInButtonAppearance.neutral,
            ),
          ]),
          gallerySection('States', [
            const TilawaGoogleSignInButton(
              label: 'Sign in with Google',
              onPressed: null,
            ),
            const SizedBox(height: 12),
            const TilawaGoogleSignInButton(
              label: 'Sign in with Google',
              isLoading: true,
              onPressed: _noop,
            ),
          ]),
        ],
      ),
    );
  }

  static Widget switchAtom(BuildContext context) {
    return GalleryDemoFrame(
      child: _SwitchDemo(),
    );
  }

  static Widget textField(BuildContext context) {
    return GalleryDemoFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          TilawaTextField(label: 'Default', hintText: 'Enter text'),
          SizedBox(height: 16),
          TilawaTextField(
            label: 'With helper',
            hintText: 'Search',
            helperText: 'Helper message',
            prefixIcon: Icon(Icons.search),
          ),
          SizedBox(height: 16),
          TilawaTextField(label: 'Password', isPassword: true),
          SizedBox(height: 16),
          TilawaTextField(
            label: 'Error',
            errorText: 'Invalid input',
          ),
        ],
      ),
    );
  }
}

void _noop() {}

class _CheckboxDemo extends StatefulWidget {
  @override
  State<_CheckboxDemo> createState() => _CheckboxDemoState();
}

class _CheckboxDemoState extends State<_CheckboxDemo> {
  bool _checked = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 16,
      children: [
        TilawaCheckbox(
          value: _checked,
          onChanged: (value) => setState(() => _checked = value ?? false),
        ),
        Text(_checked ? 'Checked' : 'Unchecked'),
      ],
    );
  }
}

class _SwitchDemo extends StatefulWidget {
  @override
  State<_SwitchDemo> createState() => _SwitchDemoState();
}

class _SwitchDemoState extends State<_SwitchDemo> {
  bool _value = true;

  @override
  Widget build(BuildContext context) {
    return TilawaSwitch(
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}
