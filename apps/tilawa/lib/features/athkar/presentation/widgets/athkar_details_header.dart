import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/tilawa_back_button.dart';

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
    final ThemeData theme = Theme.of(context);
    final Color appBarForegroundColor = theme.colorScheme.onPrimary;

    return SliverAppBar(
      expandedHeight: 100.0,
      pinned: true,
      stretch: true,
      backgroundColor: theme.primaryColor,
      foregroundColor: appBarForegroundColor,
      leading: context.canPop()
          ? TilawaBackButton(color: appBarForegroundColor)
          : null,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
      title: Column(
        children: [
          Text(
            categoryName,
            style: theme.textTheme.titleLarge?.copyWith(
              color: appBarForegroundColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (totalItems > 0)
            Text(
              '${currentPage + 1} / $totalItems',
              style: theme.textTheme.labelSmall?.copyWith(
                color: appBarForegroundColor.withValues(alpha: 0.9),
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
                backgroundColor: appBarForegroundColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  appBarForegroundColor,
                ),
              ),
            )
          : null,
    );
  }
}
