import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/shared/widgets/tilawa_back_button.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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
    final Color foregroundColor = TilawaAppBarChrome.foregroundColor(
      theme.colorScheme,
    );

    return TilawaSliverAppBar(
      expandedHeight: 100,
      stretch: true,
      leading: context.canPop()
          ? TilawaBackButton(color: foregroundColor)
          : null,
      automaticallyImplyLeading: false,
      titleWidget: Column(
        children: [
          Text(
            categoryName,
            style: theme.textTheme.titleLarge?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (totalItems > 0)
            Text(
              '${currentPage + 1} / $totalItems',
              style: theme.textTheme.labelSmall?.copyWith(
                color: foregroundColor.withValues(alpha: 0.9),
              ),
            ),
        ],
      ),
      centerTitle: false,
      bottom: totalItems > 0
          ? PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(
                value: (currentPage + 1) / totalItems,
                backgroundColor: foregroundColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
              ),
            )
          : null,
    );
  }
}
