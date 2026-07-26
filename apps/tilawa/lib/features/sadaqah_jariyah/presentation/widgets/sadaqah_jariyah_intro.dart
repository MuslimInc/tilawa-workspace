import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Quiet section title above the dedications list.
class SadaqahJariyahIntro extends StatelessWidget {
  const SadaqahJariyahIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return TilawaSectionTitle(title: context.l10n.sadaqahJariyahIntroP1);
  }
}
