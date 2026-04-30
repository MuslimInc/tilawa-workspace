import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'tilawa_ui_kit.dart';

PreviewThemeData atomsPreviewTheme() {
  return PreviewThemeData(
    materialLight: AppTheme.getLightTheme(primaryColor: AppColors.primaryCyan),
    materialDark: AppTheme.getDarkTheme(primaryColor: AppColors.primaryCyan),
  );
}

@Preview(name: 'TilawaCard', group: 'Atoms', theme: atomsPreviewTheme)
Widget previewTilawaCard() {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: TilawaCard(
          child: const Text('Tilawa card content'),
        ),
      ),
    ),
  );
}

@Preview(name: 'TilawaCard (tappable + gradient)', group: 'Atoms', theme: atomsPreviewTheme)
Widget previewTilawaCardGradient() {
  return Builder(
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: TilawaCard(
              onTap: () {},
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.tertiary],
              ),
              child: const Text(
                'Tap me',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      );
    },
  );
}

@Preview(name: 'TilawaDivider', group: 'Atoms', theme: atomsPreviewTheme)
Widget previewTilawaDivider() {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('Above'),
          TilawaDivider(),
          Text('Below'),
        ],
      ),
    ),
  );
}

@Preview(name: 'TilawaEmptyState', group: 'Atoms', theme: atomsPreviewTheme)
Widget previewTilawaEmptyState() {
  return Scaffold(
    body: TilawaEmptyState(
      icon: Icons.inbox_outlined,
      title: 'Nothing here yet',
      subtitle: 'New items will show up here once you add them.',
      action: FilledButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
    ),
  );
}

@Preview(name: 'TilawaIconBox', group: 'Atoms', theme: atomsPreviewTheme)
Widget previewTilawaIconBox() {
  return const Scaffold(
    body: Center(
      child: TilawaIconBox(icon: Icons.bookmark_rounded),
    ),
  );
}

@Preview(name: 'TilawaLoadingIndicator', group: 'Atoms', theme: atomsPreviewTheme)
Widget previewTilawaLoadingIndicator() {
  return const Scaffold(
    body: TilawaLoadingIndicator(semanticsLabel: 'Loading'),
  );
}

@Preview(name: 'TilawaSectionTitle', group: 'Atoms', theme: atomsPreviewTheme)
Widget previewTilawaSectionTitle() {
  return const Scaffold(
    body: Padding(
      padding: EdgeInsets.all(24),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TilawaSectionTitle(title: 'Section title'),
      ),
    ),
  );
}

@Preview(name: 'TilawaSheetHandle', group: 'Atoms', theme: atomsPreviewTheme)
Widget previewTilawaSheetHandle() {
  return Scaffold(
    body: Center(
      child: SizedBox(
        width: 240,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const TilawaSheetHandle(),
        ),
      ),
    ),
  );
}
