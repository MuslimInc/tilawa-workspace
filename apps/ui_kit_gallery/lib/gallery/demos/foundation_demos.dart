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

  static Widget modalBottomSheet(BuildContext context) {
    return GalleryDemoFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Opens via showTilawaModalBottomSheet with tokenized shape '
            'and max height.',
          ),
          const SizedBox(height: 16),
          TilawaButton(
            text: 'Show modal sheet',
            onPressed: () => _openModal(context),
          ),
        ],
      ),
    );
  }

  static Future<void> _openModal(BuildContext context) {
    return showTilawaModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: TilawaBottomSheetScaffold.modalShape(context),
      sheetSemanticsLabel: 'Example sheet',
      builder: (sheetContext) {
        return TilawaBottomSheetScaffold(
          topBar: Text(
            'Modal sheet',
            style: Theme.of(sheetContext).textTheme.titleMedium,
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('Foundation helper + scaffold composition.'),
            ),
          ],
        );
      },
    );
  }
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
