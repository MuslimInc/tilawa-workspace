import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'tilawa_form_validation.dart';

/// Registers a form section for scroll-to-error and accessibility targeting.
///
/// Wrap each logical field (text input, dropdown, picker, pill group) and assign
/// a stable [fieldId] plus monotonic [order] values top-to-bottom.
class TilawaFormFieldAnchor extends StatefulWidget {
  /// Creates a field anchor.
  const TilawaFormFieldAnchor({
    super.key,
    required this.fieldId,
    required this.semanticLabel,
    required this.order,
    required this.child,
    this.focusNode,
  });

  /// Stable id referenced by [TilawaFormFieldIssue.fieldId].
  final String fieldId;

  /// Accessible field name (localized by the host screen).
  final String semanticLabel;

  /// Visual order from top to bottom.
  final int order;

  /// Optional focus target for text inputs after a failed submit.
  final FocusNode? focusNode;

  /// Wrapped field UI.
  final Widget child;

  @override
  State<TilawaFormFieldAnchor> createState() => _TilawaFormFieldAnchorState();
}

class _TilawaFormFieldAnchorState extends State<TilawaFormFieldAnchor> {
  final GlobalKey _anchorKey = GlobalKey();
  TilawaFormValidationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller?.unregisterField(widget.fieldId);
    _controller = TilawaFormValidationScope.maybeOf(context);
    _controller?.registerField(
      TilawaFormFieldRegistration(
        id: widget.fieldId,
        semanticLabel: widget.semanticLabel,
        order: widget.order,
        anchorKey: _anchorKey,
        focusNode: widget.focusNode,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.unregisterField(widget.fieldId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _anchorKey,
      child: widget.child,
    );
  }
}

/// Section-level error copy shown beneath non-input controls (pill groups, etc.).
class TilawaFormSectionError extends StatelessWidget {
  /// Creates a section error line.
  const TilawaFormSectionError({super.key, this.errorText});

  /// Error message; hidden when null or empty.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    if (errorText == null || errorText!.isEmpty) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: theme.tokens.spaceExtraSmall),
      child: Text(
        errorText!,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}
