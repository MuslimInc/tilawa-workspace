import 'package:flutter/material.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciter_search_header.dart';
import 'package:tilawa/shared/widgets/tilawa_back_button.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Reciter title + search on vellum [TilawaSliverAppBar] chrome.
///
/// Elevation shadow and bottom hairline sit below the search row
/// ([ReciterDetailsSearchBar] in [AppBar.bottom]), not under the title only.
class ReciterDetailsAppBar extends StatelessWidget {
  const ReciterDetailsAppBar({
    super.key,
    required this.reciter,
    required this.searchController,
  });

  final ReciterEntity reciter;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final Color foregroundColor = TilawaAppBarChrome.foregroundColor(
      colorScheme,
    );
    final double searchBottomHeight = reciterDetailsSearchHeaderExtent(
      context,
    );

    return TilawaSliverAppBar(
      surface: TilawaAppBarSurface.parchment,
      leading: TilawaBackButton(color: foregroundColor),
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(searchBottomHeight),
        child: ReciterDetailsSearchBar(controller: searchController),
      ),
      titleWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primary.withValues(
              alpha: tokens.opacitySubtle,
            ),
            child: Text(
              reciter.name[0],
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: tokens.spaceSmall + tokens.spaceTiny),
          Flexible(
            child: Text(
              reciter.name,
              style: context
                  .responsiveStyle((t) => t.titleLarge)
                  ?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
