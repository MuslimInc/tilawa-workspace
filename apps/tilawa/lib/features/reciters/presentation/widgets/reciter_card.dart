import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router_config.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';
import '../reciter_semantics_ids.dart';
import '../utils/reciter_list_moshaf_label.dart';

/// Talabat / Booking–style list row: leading visual, text block, top-end save.
class ReciterCard extends StatelessWidget {
  const ReciterCard({
    super.key,
    required this.reciter,
  });

  final ReciterEntity reciter;

  void _openReciterDetails(BuildContext context) {
    ReciterDetailsRoute(
      reciterId: reciter.id.toString(),
      $extra: reciter,
    ).push(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return RepaintBoundary(
      child: Semantics(
        button: true,
        identifier: ReciterSemanticsIds.reciterCard(reciter.id),
        label: context.l10n.a11yOpenReciterDetails(reciter.name),
        child: TilawaCard(
          surface: TilawaCardSurface.flat,
          padding: EdgeInsets.all(tokens.spaceLarge),
          borderRadius: tokens.radiusLarge,
          onTap: () => _openReciterDetails(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.spaceMedium,
                children: [
                  _ReciterAvatar(
                    reciterId: reciter.id,
                    name: reciter.name,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        end: tokens.spaceExtraLarge,
                      ),
                      child: _ReciterInfo(reciter: reciter),
                    ),
                  ),
                ],
              ),
              PositionedDirectional(
                top: 0,
                end: 0,
                child: _FavoriteButton(reciter: reciter),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReciterAvatar extends StatelessWidget {
  const _ReciterAvatar({required this.reciterId, required this.name});

  final int reciterId;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final double size = tokens.iconSizeLarge + tokens.spaceExtraLarge;
    final Color backgroundColor = _reciterAvatarBackground(
      reciterId,
      colorScheme,
    ).withValues(alpha: tokens.opacityEmphasis);
    final Color foregroundColor = _reciterAvatarForeground(
      reciterId,
      colorScheme,
    );
    final BorderRadius radius = BorderRadius.circular(tokens.radiusLarge);

    return Semantics(
      image: true,
      label: name,
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: radius,
            border: Border.all(
              color: foregroundColor.withValues(alpha: tokens.opacityShadow),
              width: tokens.borderWidthThin * 2,
            ),
          ),
          child: Text(
            _reciterInitial(name),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: foregroundColor,
              height: 1,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

Color _reciterAvatarBackground(int reciterId, ColorScheme colorScheme) {
  final List<Color> palette = <Color>[
    colorScheme.primaryContainer,
    colorScheme.secondaryContainer,
    colorScheme.tertiaryContainer,
    colorScheme.surfaceContainerHighest,
  ];
  return palette[reciterId.abs() % palette.length];
}

Color _reciterAvatarForeground(int reciterId, ColorScheme colorScheme) {
  final List<Color> palette = <Color>[
    colorScheme.onPrimaryContainer,
    colorScheme.onSecondaryContainer,
    colorScheme.onTertiaryContainer,
    colorScheme.onSurfaceVariant,
  ];
  return palette[reciterId.abs() % palette.length];
}

String _reciterInitial(String name) {
  final String trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed.characters.first;
}

class _ReciterInfo extends StatelessWidget {
  const _ReciterInfo({required this.reciter});

  final ReciterEntity reciter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final int moshafCount = reciter.moshaf.length;
    final String? moshafLabel = moshafCount > 0
        ? buildReciterListMoshafLabel(
            moshaf: reciter.moshaf,
            additionalMoshafLabel: context.l10n.reciterAdditionalMoshafCount,
          )
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spaceExtraSmall,
      children: [
        Text(
          reciter.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        // Flexible: grid tiles cap the card height (e.g. tablet two-column
        // layout); the label drops to one line there instead of overflowing.
        if (moshafLabel != null)
          Flexible(
            child: Text(
              moshafLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )
        else if (moshafCount == 0)
          Flexible(
            child: Text(
              context.l10n.recitationsAvailable(moshafCount),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.reciter});

  final ReciterEntity reciter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final bool isFavorite = context.select<FavoritesCubit, bool>((cubit) {
      final FavoritesState favoritesState = cubit.state;
      return favoritesState is FavoritesLoaded &&
          favoritesState.favoriteIds.contains(reciter.id);
    });

    return Semantics(
      identifier: ReciterSemanticsIds.reciterFavoriteButton(reciter.id),
      child: TilawaIconToggle(
        icon: Icons.favorite_border_rounded,
        activeIcon: Icons.favorite_rounded,
        value: isFavorite,
        onChanged: (_) =>
            context.read<FavoritesCubit>().toggleFavorite(reciter),
        iconSize: tokens.iconSizeSmall,
        padding: tokens.spaceExtraSmall,
        activeIconColor: colorScheme.primary.withValues(
          alpha: tokens.opacityEmphasis,
        ),
        inactiveIconColor: colorScheme.onSurfaceVariant.withValues(
          alpha: tokens.opacityMedium,
        ),
        activeBackgroundColor: Colors.transparent,
        inactiveBackgroundColor: Colors.transparent,
        semanticLabel: isFavorite
            ? context.l10n.removeFromFavorites
            : context.l10n.addToFavorites,
      ),
    );
  }
}
