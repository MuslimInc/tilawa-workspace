import 'package:fluentui_system_icons/fluentui_system_icons.dart';
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

class ReciterCard extends StatelessWidget {
  const ReciterCard({super.key, required this.reciter});

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
    final colorScheme = theme.colorScheme;

    final BorderRadius borderRadius = BorderRadius.circular(tokens.radiusLarge);

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: borderRadius,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(
                alpha: tokens.opacityMedium,
              ),
              width: tokens.borderWidthThin,
            ),
          ),
          child: InkWell(
            borderRadius: borderRadius,
            onTap: () => _openReciterDetails(context),
            child: Semantics(
              button: true,
              identifier: ReciterSemanticsIds.reciterCard(reciter.id),
              label: context.l10n.a11yOpenReciterDetails(reciter.name),
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceMedium),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: tokens.spaceMedium,
                  children: [
                    _ReciterAvatar(reciterId: reciter.id, name: reciter.name),
                    Expanded(child: _ReciterInfo(reciter: reciter)),
                    _FavoriteButton(reciter: reciter),
                  ],
                ),
              ),
            ),
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
    const double size = 48;
    final Color backgroundColor = _reciterAvatarBackground(
      reciterId,
      colorScheme,
    ).withValues(alpha: tokens.opacityEmphasis);
    final Color foregroundColor = _reciterAvatarForeground(
      reciterId,
      colorScheme,
    );

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
            borderRadius: BorderRadius.circular(tokens.radiusMedium),
            border: Border.all(
              color: foregroundColor.withValues(
                alpha: tokens.opacitySubtle,
              ),
              width: tokens.borderWidthThin,
            ),
          ),
          child: Text(
            _reciterInitial(name),
            style: theme.textTheme.titleMedium?.copyWith(
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
      children: [
        Text(
          reciter.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            height: 1.25,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (moshafLabel != null) ...[
          SizedBox(height: tokens.spaceExtraSmall),
          _MoshafMetadataRow(label: moshafLabel),
        ] else if (moshafCount == 0) ...[
          SizedBox(height: tokens.spaceExtraSmall),
          Text(
            context.l10n.recitationsAvailable(moshafCount),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _MoshafMetadataRow extends StatelessWidget {
  const _MoshafMetadataRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spaceExtraSmall,
      children: [
        Padding(
          padding: EdgeInsets.only(top: tokens.spaceTiny / 2),
          child: Icon(
            FluentIcons.book_24_regular,
            size: tokens.iconSizeSmall,
            color: colorScheme.primary.withValues(
              alpha: tokens.opacityEmphasis,
            ),
          ),
        ),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
            maxLines: 2,
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
      final FavoritesState state = cubit.state;
      return state is FavoritesLoaded && state.favoriteIds.contains(reciter.id);
    });

    return Semantics(
      identifier: ReciterSemanticsIds.reciterFavoriteButton(reciter.id),
      child: TilawaIconToggle(
        icon: Icons.favorite_outline_rounded,
        activeIcon: Icons.favorite_rounded,
        value: isFavorite,
        onChanged: (_) =>
            context.read<FavoritesCubit>().toggleFavorite(reciter),
        iconSize: tokens.iconSizeMedium,
        activeIconColor: colorScheme.primary,
        inactiveIconColor: colorScheme.onSurfaceVariant.withValues(
          alpha: tokens.opacityMedium,
        ),
        activeBackgroundColor: isFavorite
            ? colorScheme.primaryContainer.withValues(
                alpha: tokens.opacitySubtle,
              )
            : colorScheme.surfaceContainerHighest.withValues(
                alpha: tokens.opacitySubtle,
              ),
        inactiveBackgroundColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: tokens.opacitySubtle,
        ),
        semanticLabel: isFavorite
            ? context.l10n.removeFromFavorites
            : context.l10n.addToFavorites,
      ),
    );
  }
}
