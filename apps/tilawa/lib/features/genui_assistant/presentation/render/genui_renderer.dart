import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/genui_document.dart';
import '../../domain/entities/genui_node.dart';
import 'components/genui_components.dart';
import 'genui_action_dispatcher.dart';
import 'genui_component_registry.dart';
import 'genui_render_scope.dart';
import 'genui_strings.dart';
import 'trusted_content_resolver.dart';

/// Walks a validated [GenUiDocument] into a widget tree of ui_kit components.
///
/// The renderer is *total* over the schema: every node either resolves to a
/// whitelisted component or renders [GenUiUnknownComponent]. It always prepends
/// the standing AI disclosure so it cannot be omitted by a payload.
class GenUiRenderer extends StatelessWidget {
  const GenUiRenderer({
    super.key,
    required this.document,
    required this.registry,
    required this.dispatcher,
    required this.content,
  });

  final GenUiDocument document;
  final GenUiComponentRegistry registry;
  final GenUiActionDispatcher dispatcher;
  final TrustedContentResolver content;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _DisclosureBanner(note: document.assistantNote),
        SizedBox(height: theme.tokens.spaceMedium),
        for (final GenUiNode node in document.nodes) _renderNode(context, node),
      ],
    );
  }

  Widget _renderNode(BuildContext context, GenUiNode node) {
    final GenUiRenderScope scope = GenUiRenderScope(
      content: content,
      dispatcher: dispatcher,
      renderChild: _renderNode,
    );
    final GenUiComponentBuilder? builder = registry.resolve(node.type);
    if (builder == null) {
      return GenUiUnknownComponent(type: node.type);
    }
    return builder(context, node, scope);
  }
}

/// Standing, renderer-owned disclosure. Frames any model-authored [note] and
/// makes clear the surface is AI-assisted and not a religious ruling.
class _DisclosureBanner extends StatelessWidget {
  const _DisclosureBanner({this.note});

  final String? note;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return TilawaCard(
      surface: TilawaCardSurface.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.auto_awesome_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: theme.tokens.spaceExtraSmall),
              Expanded(
                child: Text(
                  GenUiStrings.aiDisclosure,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (note != null && note!.isNotEmpty) ...<Widget>[
            SizedBox(height: theme.tokens.spaceExtraSmall),
            Text(note!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
