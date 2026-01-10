import 'package:flutter/material.dart';

class QuranReaderAppBar extends StatelessWidget {
  const QuranReaderAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onSearch,
    required this.onSettings,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Leading: Back Button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),

              // Center: Title & Subtitle
              if (title.isNotEmpty)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),

              // Trailing: Actions
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onSettings,
                      icon: const Icon(Icons.settings_outlined),
                      color: Theme.of(context).colorScheme.onSurface,
                      tooltip: 'Settings',
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Implement Calendar/Daily feature
                      },
                      icon: const Icon(Icons.calendar_month_outlined),
                      color: Theme.of(context).colorScheme.onSurface,
                      tooltip: 'Daily Content',
                    ),
                    IconButton(
                      onPressed: onSearch,
                      icon: const Icon(Icons.search_rounded),
                      color: Theme.of(context).colorScheme.onSurface,
                      tooltip: 'Search',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
