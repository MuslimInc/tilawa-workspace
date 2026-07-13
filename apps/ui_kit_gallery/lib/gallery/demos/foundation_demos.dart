import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'demo_helpers.dart';

/// Foundation layout and helper demos.
abstract final class FoundationDemos {
  static Widget contentBounds(BuildContext context) {
    return GalleryDemoFrame(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  Text(
                    'Viewport ${constraints.maxWidth.toStringAsFixed(0)} logical px',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  for (final kind in TilawaContentKind.values)
                    _BoundsSample(kind: kind),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget contentGrid(BuildContext context) {
    return GalleryDemoFrame(
      padding: EdgeInsets.zero,
      scrollable: false,
      child: TilawaContentGrid(
        targetItemExtent: 160,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) {
          return TilawaCard(
            child: Center(child: Text('Item ${index + 1}')),
          );
        },
      ),
    );
  }

  static Widget dialog(BuildContext context) {
    return GalleryDemoFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          const Text(
            'Centered confirm and picker dialogs with stacked actions.',
          ),
          TilawaButton(
            text: 'Confirm dialog',
            variant: TilawaButtonVariant.danger,
            onPressed: () => _openConfirmDialog(context),
          ),
          TilawaButton(
            text: 'Picker dialog',
            variant: TilawaButtonVariant.outline,
            onPressed: () => _openPickerDialog(context),
          ),
        ],
      ),
    );
  }

  static Widget modalBottomSheet(BuildContext context) {
    return GalleryDemoFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          const Text(
            'Sheet presets with sticky footer actions in the thumb zone.',
          ),
          TilawaButton(
            text: 'Basic modal',
            variant: TilawaButtonVariant.outline,
            onPressed: () => _openBasicModal(context),
          ),
          TilawaButton(
            text: 'Form sheet',
            onPressed: () => _openFormSheet(context),
          ),
          TilawaButton(
            text: 'Picker sheet',
            variant: TilawaButtonVariant.secondary,
            onPressed: () => _openPickerSheet(context),
          ),
          TilawaButton(
            text: 'Confirm sheet',
            variant: TilawaButtonVariant.danger,
            onPressed: () => _openConfirmSheet(context),
          ),
        ],
      ),
    );
  }

  static Future<void> _openConfirmDialog(BuildContext context) {
    return showTilawaConfirmDialog(
      context: context,
      title: 'Delete bookmark?',
      message: 'This removes the bookmark from your saved list.',
      confirmLabel: 'Delete',
    );
  }

  static Future<void> _openPickerDialog(BuildContext context) {
    return showTilawaPickerDialog<void>(
      context: context,
      title: 'Choose reciter',
      bodyBuilder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final name in ['Abdul Basit', 'Al-Afasy', 'Al-Husary'])
              TilawaSelectionTile(
                title: name,
                isSelected: name == 'Al-Afasy',
                onTap: () => Navigator.pop(ctx),
              ),
          ],
        );
      },
    );
  }

  static Future<void> _openBasicModal(BuildContext context) {
    return showTilawaModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: TilawaBottomSheetScaffold.modalShape(context),
      sheetSemanticsLabel: 'Example sheet',
      builder: (sheetContext) {
        return const TilawaBottomSheetScaffold(
          topBar: TilawaBottomSheetTitleRow(
            title: 'Modal sheet',
            trailingClose: true,
          ),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('Foundation helper + scaffold composition.'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _openFormSheet(BuildContext context) {
    return showTilawaFormSheet<void>(
      context: context,
      title: 'Notification settings',
      sheetSemanticsLabel: 'Notification settings form',
      primaryLabel: 'Save',
      onPrimary: () => Navigator.pop(context),
      secondaryLabel: 'Cancel',
      onSecondary: () => Navigator.pop(context),
      bodyBuilder: (ctx) {
        final padding = TilawaBottomSheetScaffold.resolvedBodyPadding(ctx);
        return ListView(
          padding: padding,
          children: const [
            TilawaSettingsSwitchTile(
              icon: Icons.notifications_active_outlined,
              title: 'Prayer reminders',
              value: true,
              onChanged: _noop,
            ),
            TilawaSettingsSwitchTile(
              icon: Icons.volume_up_outlined,
              title: 'Play adhan',
              value: false,
              onChanged: _noop,
            ),
          ],
        );
      },
    );
  }

  static Future<void> _openPickerSheet(BuildContext context) {
    return showTilawaPickerSheet<void>(
      context: context,
      title: 'Choose reciter',
      doneLabel: 'Done',
      onDone: () => Navigator.pop(context),
      bodyBuilder: (ctx) {
        final padding = TilawaBottomSheetScaffold.resolvedBodyPadding(ctx);
        return ListView.builder(
          padding: padding,
          itemCount: 8,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text('Reciter ${index + 1}'),
              onTap: () {},
            );
          },
        );
      },
    );
  }

  static Future<void> _openConfirmSheet(BuildContext context) {
    return showTilawaConfirmSheet(
      context: context,
      title: 'Delete bookmark?',
      message: 'This removes the bookmark from your saved list.',
      confirmLabel: 'Delete',
      onConfirm: () => Navigator.pop(context, true),
    );
  }

  static void _noop(bool _) {}
}

class _BoundsSample extends StatelessWidget {
  const _BoundsSample({required this.kind});

  final TilawaContentKind kind;

  @override
  Widget build(BuildContext context) {
    final maxWidth = TilawaContentBounds.resolveMaxWidth(context, kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          kind.name,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        TilawaContentBounds(
          kind: kind,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Max width $maxWidth dp'),
          ),
        ),
      ],
    );
  }
}
