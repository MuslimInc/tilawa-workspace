import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciter_catalog_chrome.dart';
import 'package:tilawa/shared/widgets/quran_player_chrome.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class MoshafSelector extends StatelessWidget {
  const MoshafSelector({super.key, required this.reciter, required this.state});
  final ReciterEntity reciter;
  final ReciterDetailsState state;

  @override
  Widget build(BuildContext context) {
    context.watch<QuranPlayerChromeNotifier>();
    context.select(
      (AudioPlayerBloc bloc) => (
        bloc.state.shouldShowBottomPlayer,
        bloc.state.currentAudio?.id,
      ),
    );

    final List<MoshafEntity> uniqueMoshaf = reciter.moshaf.toSet().toList();
    final MoshafEntity selectedMoshaf =
        state.selectedMoshaf ?? uniqueMoshaf.first;
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final BorderRadius borderRadius = BorderRadius.circular(tokens.radiusLarge);
    final Color fill = ReciterCatalogChrome.controlIdleFill(
      context,
      colorScheme,
    );
    final Color borderColor = ReciterCatalogChrome.controlBorder(
      context,
      colorScheme,
      tokens,
    );
    final RoundedRectangleBorder fieldShape = RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: BorderSide(
        color: borderColor,
        width: tokens.borderWidthThin,
      ),
    );
    final TextStyle labelStyle = theme.textTheme.bodySmall!.copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceExtraSmall,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double? menuWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : null;

          return MenuAnchor(
            crossAxisUnconstrained: false,
            alignmentOffset: Offset(0, tokens.dropdownMenuGap),
            style: MenuStyle(
              alignment: AlignmentDirectional.bottomStart,
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(fill),
              surfaceTintColor: const WidgetStatePropertyAll(
                Colors.transparent,
              ),
              shadowColor: WidgetStatePropertyAll(
                colorScheme.shadow.withValues(alpha: 0.08),
              ),
              side: WidgetStatePropertyAll(BorderSide(color: borderColor)),
              shape: WidgetStatePropertyAll(fieldShape),
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
              minimumSize: menuWidth == null
                  ? null
                  : WidgetStatePropertyAll(Size(menuWidth, 0)),
              maximumSize: menuWidth == null
                  ? null
                  : WidgetStatePropertyAll(Size(menuWidth, double.infinity)),
            ),
            menuChildren: [
              for (final MoshafEntity moshaf in uniqueMoshaf)
                MenuItemButton(
                  style: MenuItemButton.styleFrom(
                    minimumSize: Size(
                      menuWidth ?? tokens.minInteractiveDimension,
                      tokens.minInteractiveDimension,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spaceMedium,
                    ),
                    textStyle: labelStyle,
                    alignment: AlignmentDirectional.centerStart,
                  ),
                  onPressed: () {
                    context.read<ReciterDetailsBloc>().add(
                      LoadSurahList(reciter: reciter, moshaf: moshaf),
                    );
                  },
                  child: Text(
                    moshaf.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
            ],
            builder:
                (
                  BuildContext context,
                  MenuController controller,
                  Widget? child,
                ) {
                  void toggleMenu() {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  }

                  return Semantics(
                    button: true,
                    expanded: controller.isOpen,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: tokens.minInteractiveDimension,
                      ),
                      child: TilawaInteractiveSurface(
                        onTap: toggleMenu,
                        button: false,
                        borderRadius: borderRadius,
                        materialColor: fill,
                        materialShape: fieldShape,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: tokens.spaceSmall,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  uniqueMoshaf.contains(selectedMoshaf)
                                      ? selectedMoshaf.name
                                      : uniqueMoshaf.first.name,
                                  style: labelStyle,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: tokens.iconSizeLarge,
                                color: colorScheme.onSurface,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
          );
        },
      ),
    );
  }
}
