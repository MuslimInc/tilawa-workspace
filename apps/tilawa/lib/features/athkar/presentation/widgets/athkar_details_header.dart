import 'package:flutter/material.dart';

class AthkarDetailsHeader extends StatelessWidget {
  const AthkarDetailsHeader({
    super.key,
    required this.categoryName,
    required this.currentPage,
    required this.totalItems,
  });

  final String categoryName;
  final int currentPage;
  final int totalItems;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100.0,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
      title: Column(
        children: [
          Text(
            categoryName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (totalItems > 0)
            Text(
              '${currentPage + 1} / $totalItems',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
        ],
      ),
      centerTitle: true,
      bottom: totalItems > 0
          ? PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(
                value: (currentPage + 1) / totalItems,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : null,
    );
  }
}
