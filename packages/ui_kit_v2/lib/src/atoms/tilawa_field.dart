import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

/// Text input field. Mirrors `.tw-field` — 48px tall, hairline border,
/// optional label / helper / icons / error state.
class TilawaField extends StatefulWidget {
  const TilawaField({
    this.controller,
    this.label,
    this.placeholder,
    this.help,
    this.errorText,
    this.leadingIcon,
    this.trailingIcon,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    super.key,
  });

  final TextEditingController? controller;
  final String? label;
  final String? placeholder;
  final String? help;
  final String? errorText;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;

  @override
  State<TilawaField> createState() => _TilawaFieldState();
}

class _TilawaFieldState extends State<TilawaField> {
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
    final hasError = (widget.errorText ?? '').isNotEmpty;
    final focused = _focus.hasFocus;

    final borderColor = hasError
        ? c.danger
        : focused
        ? c.brandLight
        : c.hairline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if ((widget.label ?? '').isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Text(
              widget.label!,
              style: theme.typography.captionMobile.copyWith(
                fontWeight: FontWeight.w600,
                color: c.fg1,
              ),
            ),
          ),
        ],
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: c.bgCard,
            borderRadius: TilawaRadii.brMd,
            border: Border.all(color: borderColor),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: c.brand.withValues(alpha: 0.08),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              if (widget.leadingIcon != null) ...[
                Icon(widget.leadingIcon, size: 18, color: c.fg2),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  focusNode: _focus,
                  controller: widget.controller,
                  enabled: widget.enabled,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: theme.typography.bodyMobile.copyWith(color: c.fg1),
                  cursorColor: c.brand,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.placeholder,
                    hintStyle: theme.typography.bodyMobile.copyWith(
                      color: c.fg2,
                    ),
                  ),
                ),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 10),
                Icon(widget.trailingIcon, size: 18, color: c.fg2),
              ],
            ],
          ),
        ),
        if ((widget.help ?? widget.errorText ?? '').isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              hasError ? widget.errorText! : widget.help!,
              style: TextStyle(
                fontFamily: TilawaFontFamily.ui,
                fontSize: 11,
                height: 1.5,
                color: hasError ? c.danger : c.fg2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
