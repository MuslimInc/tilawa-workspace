import 'package:flutter/widgets.dart';

import '../../domain/entities/genui_node.dart';
import 'genui_action_dispatcher.dart';
import 'trusted_content_resolver.dart';

/// Per-render dependencies handed to each component builder.
///
/// Carries the trusted content resolver (so components render app-owned data,
/// not model text), the action dispatcher (so a tap can only fire an
/// allowlisted intent), and [renderChild] for recursive container components.
class GenUiRenderScope {
  const GenUiRenderScope({
    required this.content,
    required this.dispatcher,
    required this.renderChild,
  });

  final TrustedContentResolver content;
  final GenUiActionDispatcher dispatcher;

  /// Renders a child node through the same whitelist (unknown → fallback).
  final Widget Function(BuildContext context, GenUiNode node) renderChild;
}
