import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../domain/entities/genui_node.dart';
import '../genui_render_scope.dart';
import '../genui_strings.dart';

/// Signature for a whitelisted component builder. The registry maps a node
/// [type] string to exactly one of these; unknown types never reach here.
typedef GenUiComponentBuilder =
    Widget Function(
      BuildContext context,
      GenUiNode node,
      GenUiRenderScope scope,
    );

/// `SectionStack` → a token-spaced [Column]. Layout-only; the model gets no
/// control over alignment beyond stacking trusted children vertically.
class GenUiSectionStack extends StatelessWidget {
  const GenUiSectionStack({super.key, required this.node, required this.scope});

  final GenUiNode node;
  final GenUiRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final double gap = Theme.of(context).tokens.spaceMedium;
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < node.children.length; i++) {
      if (i > 0) children.add(SizedBox(height: gap));
      children.add(scope.renderChild(context, node.children[i]));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

/// `PlanHeader` → [TilawaSectionHeader]. The title is non-authoritative chrome
/// copy; it never carries religious content.
class GenUiPlanHeader extends StatelessWidget {
  const GenUiPlanHeader({super.key, required this.node});

  final GenUiNode node;

  static const Map<String, String> _titles = <String, String>{
    'smartQuranPlan': 'Smart Quran Plan',
    'todayWird': "Today's Wird",
  };

  @override
  Widget build(BuildContext context) {
    final String? key = node.stringProp('titleKey');
    final String title =
        _titles[key] ?? node.stringProp('title') ?? 'Your plan';
    return TilawaSectionHeader(title: title);
  }
}

/// `WirdCard` → [TilawaCard]. Shows a trusted range label; the underlying plan
/// is referenced by `planId` and resolved by the app, not authored by the model.
class GenUiWirdCard extends StatelessWidget {
  const GenUiWirdCard({super.key, required this.node, required this.scope});

  final GenUiNode node;
  final GenUiRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String label = node.stringProp('rangeLabel') ?? '—';
    return TilawaCard(
      child: Row(
        children: <Widget>[
          Icon(Icons.menu_book_outlined, color: theme.colorScheme.primary),
          SizedBox(width: theme.tokens.spaceSmall),
          Expanded(
            child: Text(label, style: theme.textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

/// `AyahReferenceCard` → [TilawaCard]. The reference label comes from the
/// trusted content resolver, never from the model payload.
class GenUiAyahReferenceCard extends StatelessWidget {
  const GenUiAyahReferenceCard({
    super.key,
    required this.node,
    required this.scope,
  });

  final GenUiNode node;
  final GenUiRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int? surah = node.intProp('surah');
    if (surah == null || surah < 1 || surah > 114) {
      return GenUiUnknownComponent(type: 'AyahReferenceCard(invalid surah)');
    }
    final int? ayah = node.intProp('ayah');
    final String label = scope.content.ayahReferenceLabel(surah, ayah: ayah);
    return TilawaCard(
      surface: TilawaCardSurface.flat,
      child: Row(
        children: <Widget>[
          Icon(Icons.bookmark_border, color: theme.colorScheme.primary),
          SizedBox(width: theme.tokens.spaceSmall),
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

/// `InfoNote` → outlined [TilawaCard]. Holds short non-authoritative copy and
/// also styles the standing AI disclosure.
class GenUiInfoNote extends StatelessWidget {
  const GenUiInfoNote({super.key, required this.node});

  final GenUiNode node;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String text = node.stringProp('text') ?? '';
    return TilawaCard(
      surface: TilawaCardSurface.outline,
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// `ActionButton` → [TilawaButton]. Tapping dispatches the node's action, which
/// can only ever fire an allowlisted, bounds-checked intent (or be rejected).
class GenUiActionButton extends StatelessWidget {
  const GenUiActionButton({super.key, required this.node, required this.scope});

  final GenUiNode node;
  final GenUiRenderScope scope;

  static const Map<String, String> _labels = <String, String>{
    'startTodayWird': "Start today's wird",
    'openQuranReader': 'Open Quran',
    'openAthkar': 'Open athkar',
    'setReminder': 'Set reminder',
    'savePlan': 'Save plan',
  };

  @override
  Widget build(BuildContext context) {
    final String? key = node.stringProp('labelKey');
    final String label = _labels[key] ?? node.stringProp('label') ?? 'Continue';
    return TilawaButton(
      text: label,
      isFullWidth: true,
      onPressed: () => scope.dispatcher.dispatch(node),
    );
  }
}

/// Safe fallback for any component the client does not recognise. Renders a
/// muted [TilawaCard] instead of crashing or leaving a blank gap.
class GenUiUnknownComponent extends StatelessWidget {
  const GenUiUnknownComponent({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return TilawaCard(
      surface: TilawaCardSurface.outline,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.help_outline,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: theme.tokens.spaceSmall),
          Expanded(
            child: Text(
              GenUiStrings.unknownComponent,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
