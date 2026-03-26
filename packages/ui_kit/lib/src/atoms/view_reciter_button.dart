import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import '../foundation/design_tokens.dart';

class ViewReciterButton extends StatelessWidget {
  const ViewReciterButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Padding(
      padding: EdgeInsetsDirectional.only(start: tokens.spaceMedium),
      child: TextButton.icon(
        icon: Icon(
          FluentIcons.person_24_regular,
          size: tokens.iconSizeMedium - 2,
        ),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}
