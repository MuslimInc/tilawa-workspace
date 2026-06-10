import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/shared/widgets/quran_player_widget.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router_config.dart';
import '../../domain/entities/athkar_category.dart';
import '../cubit/athkar_cubit.dart';
import '../cubit/athkar_state.dart';
import '../widgets/athkar_ambient_background.dart';
import '../widgets/athkar_category_card.dart';

String _localizedAthkarCategoryTitle(
  BuildContext context,
  AthkarCategory category,
) {
  if (context.isArabic) return category.nameAr;
  final String english = category.nameEn.trim();
  return english.isNotEmpty ? english : category.nameAr;
}

class AthkarCategoriesScreen extends StatelessWidget {
  const AthkarCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final double fabBottomOffset =
        QuranPlayerWidget.fabBottomOffset(context) + tokens.spaceLarge;
    return Scaffold(
      appBar: TilawaCatalogAppBar.titleOnly(
        context,
        title: context.l10n.athkar,
      ),
      floatingActionButton: FloatingActionButton.extended(
        // Unique tag prevents this FAB's default Hero from colliding with
        // another screen's FAB during route transitions (e.g. the Athkar tab
        // FAB flying into Reciter Details while the tab is offstage in the
        // shell's IndexedStack).
        heroTag: 'athkar_tasbeeh_fab',
        onPressed: () => const TasbeehRoute().push(context),
        icon: const Icon(Icons.auto_awesome_rounded),
        label: Text(context.l10n.tasbeehCategory),
      ),
      floatingActionButtonLocation: _StartFloatingActionButtonLocation(
        offset: fabBottomOffset,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AthkarAmbientBackground()),
          BlocBuilder<AthkarCubit, AthkarState>(
            builder: (context, state) {
              if (state is AthkarLoading || state is AthkarInitial) {
                return const TilawaLoadingIndicator();
              } else if (state is AthkarError) {
                final message =
                    state.failure.message ?? context.l10n.unexpectedError;
                return TilawaIllustratedState(
                  visual: const TilawaStateVisual(
                    icon: Icons.menu_book_rounded,
                    tone: TilawaStateVisualTone.error,
                  ),
                  title: message,
                  semanticLabel: message,
                  primaryAction: TilawaButton(
                    text: context.l10n.retry,
                    variant: TilawaButtonVariant.secondary,
                    leadingIcon: const Icon(Icons.refresh_rounded),
                    onPressed: () {
                      context.read<AthkarCubit>().loadCategories();
                    },
                  ),
                );
              } else if (state is AthkarCategoriesLoaded) {
                final double fabClearance =
                    fabBottomOffset +
                    kMinInteractiveDimension +
                    (tokens.spaceLarge * 2);

                return TilawaContentGrid(
                  padding: EdgeInsets.fromLTRB(
                    tokens.spaceLarge,
                    tokens.spaceLarge,
                    tokens.spaceLarge,
                    fabClearance,
                  ),
                  targetItemExtent: 180,
                  crossAxisSpacing: tokens.spaceLarge,
                  mainAxisSpacing: tokens.spaceLarge,
                  childAspectRatio: 1.0,
                  itemCount: state.categories.length,
                  itemBuilder: (context, index) {
                    final AthkarCategory category = state.categories[index];
                    return AthkarCategoryCard(
                      name: _localizedAthkarCategoryTitle(context, category),
                      icon: category.icon,
                      onTap: () {
                        AthkarDetailsRoute(
                          categoryId: category.id,
                          categoryName: _localizedAthkarCategoryTitle(
                            context,
                            category,
                          ),
                        ).push(context);
                      },
                    );
                  },
                );
              }
              return const TilawaLoadingIndicator();
            },
          ),
        ],
      ),
    );
  }
}

class _StartFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const _StartFloatingActionButtonLocation({required this.offset});

  final double offset;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final Offset base = FloatingActionButtonLocation.startFloat.getOffset(
      scaffoldGeometry,
    );
    final double y =
        scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.floatingActionButtonSize.height -
        offset;
    return Offset(base.dx, y);
  }
}
