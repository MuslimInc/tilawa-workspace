import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class KhatmaCompletionDuaScreen extends StatelessWidget {
  const KhatmaCompletionDuaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return TilawaShellChildScaffold(
      appBar: TilawaCatalogAppBar.titleOnly(
        title: context.l10n.khatmaCompletionDuaTitle,
        automaticallyImplyLeading: true,
        onBackPressed: () => context.pop(),
      ),
      body: ListView(
        padding: EdgeInsetsDirectional.fromSTEB(
          theme.componentTokens.settingsGroup.groupHorizontalPadding,
          tokens.spaceLarge,
          theme.componentTokens.settingsGroup.groupHorizontalPadding,
          tokens.spaceHuge,
        ),
        children: [
          Text(
            context.l10n.khatmaDuaBody,
            style: theme.textTheme.headlineSmall?.copyWith(
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
