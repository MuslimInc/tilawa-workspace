import 'package:flutter/material.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciter_search_header.dart';
import 'package:tilawa/shared/widgets/profile_avatar.dart';
import 'package:tilawa/shared/widgets/tilawa_back_button.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/utils/reciter_portrait_catalog.dart';
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
    final TextStyle? titleStyle = theme.textTheme.titleLarge?.copyWith(
      color: foregroundColor,
      fontWeight: FontWeight.w700,
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
          ProfileAvatar(
            photoUrl: ReciterPortraitCatalog.photoUrlFor(reciter.id),
            displayName: reciter.name,
            size: tokens.iconBoxSize,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            fallbackStyle: ProfileAvatarFallbackStyle.initial,
            textStyle: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: tokens.spaceSmall + tokens.spaceTiny),
          Flexible(
            child: Text(
              reciter.name,
              style: titleStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
