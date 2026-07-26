import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class SadaqahJariyahAddCta extends StatelessWidget {
  const SadaqahJariyahAddCta({
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TilawaButton(
      text: context.l10n.sadaqahJariyahSupportCta,
      isFullWidth: true,
      onPressed: enabled ? onPressed : null,
    );
  }
}
