import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/changelog_release.dart';
import 'whats_new_sheet_body.dart';

/// Opens the what's new bottom sheet with shared scaffold chrome.
Future<void> showWhatsNewSheet({
  required BuildContext context,
  required ChangelogRelease release,
  required List<String> highlights,
}) {
  final l10n = context.l10n;
  final ColorScheme colorScheme = Theme.of(context).colorScheme;

  return showTilawaModalBottomSheet<void>(
    context: context,
    backgroundColor: colorScheme.surface,
    shape: TilawaBottomSheetScaffold.modalShape(context),
    sheetSemanticsLabel: l10n.whatsNewSemanticsLabel(release.version),
    builder: (BuildContext sheetContext) {
      final double maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.75;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: TilawaBottomSheetScaffold(
          topBar: TilawaBottomSheetTitleRow(
            title: l10n.whatsNewTitle(release.version),
            trailingClose: true,
            onClose: () => Navigator.of(context).pop(),
          ),
          betweenTopBarAndBody: const <Widget>[TilawaDivider(height: 1)],
          footer: TilawaBottomSheetActions(
            primaryLabel: l10n.whatsNewGotIt,
            onPrimary: () => Navigator.of(context).pop(),
          ),
          children: <Widget>[
            Flexible(
              fit: FlexFit.loose,
              child: WhatsNewSheetBody(highlights: highlights),
            ),
          ],
        ),
      );
    },
  );
}
