import 'package:flutter/material.dart';

import '../gallery_catalog.dart';
import '../gallery_entry.dart';
import 'gallery_detail_screen.dart';

/// Home screen listing all UI Kit components by category.
class GalleryHomeScreen extends StatefulWidget {
  const GalleryHomeScreen({super.key});

  @override
  State<GalleryHomeScreen> createState() => _GalleryHomeScreenState();
}

class _GalleryHomeScreenState extends State<GalleryHomeScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final grouped = groupGalleryCatalog();
    final normalizedQuery = _query.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tilawa UI Kit'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchBar(
              hintText: 'Search components',
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        ),
      ),
      body: ListView(
        children: [
          for (final category in GalleryCategory.values)
            if (_entriesForCategory(
              grouped[category]!,
              normalizedQuery,
            ).isNotEmpty)
              _CategorySection(
                category: category,
                entries: _entriesForCategory(
                  grouped[category]!,
                  normalizedQuery,
                ),
                onTap: _openEntry,
              ),
        ],
      ),
    );
  }

  List<GalleryEntry> _entriesForCategory(
    List<GalleryEntry> entries,
    String query,
  ) {
    if (query.isEmpty) return entries;
    return entries
        .where(
          (e) =>
              e.name.toLowerCase().contains(query) ||
              (e.description?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  void _openEntry(GalleryEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GalleryDetailScreen(entry: entry),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.entries,
    required this.onTap,
  });

  final GalleryCategory category;
  final List<GalleryEntry> entries;
  final ValueChanged<GalleryEntry> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            category.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...entries.map(
          (entry) => ListTile(
            title: Text(entry.name),
            subtitle: entry.description == null
                ? null
                : Text(entry.description!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onTap(entry),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
