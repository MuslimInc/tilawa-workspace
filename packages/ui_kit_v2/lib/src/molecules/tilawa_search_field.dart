import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

/// Compact search field with a leading magnifier icon. Mirrors
/// `.tw-searchfield`. 44px tall, hairline border, focused brand-glow.
class TilawaSearchField extends StatefulWidget {
  const TilawaSearchField({
    this.controller,
    this.placeholder = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController? controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  State<TilawaSearchField> createState() => _TilawaSearchFieldState();
}

class _TilawaSearchFieldState extends State<TilawaSearchField> {
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TilawaTheme.of(context);
    final c = theme.tokens.colors;
    final focused = _focus.hasFocus;

    return Container(
      height: TilawaSpacing.tapMin,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: TilawaRadii.brMd,
        border: Border.all(
          color: focused ? c.brandLight : c.hairline,
        ),
        boxShadow: focused
            ? [
                ...TilawaShadows.el1,
                BoxShadow(
                  color: c.brand.withValues(alpha: 0.08),
                  spreadRadius: 3,
                ),
              ]
            : TilawaShadows.el1,
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: c.fg2),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              focusNode: _focus,
              controller: widget.controller,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              textInputAction: TextInputAction.search,
              style: theme.typography.bodyMobile.copyWith(color: c.fg1),
              cursorColor: c.brand,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.placeholder,
                hintStyle: theme.typography.bodyMobile.copyWith(color: c.fg2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
