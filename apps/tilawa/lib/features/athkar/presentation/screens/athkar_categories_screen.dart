import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/shared/widgets/quran_player_widget.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router_config.dart';
import '../../domain/entities/athkar_category.dart';
import '../athkar_category_presentation.dart';
import '../cubit/athkar_cubit.dart';
import '../cubit/athkar_state.dart';
import '../widgets/athkar_ambient_background.dart';
import '../widgets/athkar_category_card.dart';

class AthkarCategoriesScreen extends StatelessWidget {
  const AthkarCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final double bottomPadding =
        QuranPlayerWidget.fabBottomOffset(context) + tokens.spaceLarge;
    return Scaffold(
      appBar: TilawaCatalogAppBar.titleOnly(
        context,
        title: context.l10n.athkar,
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
                return TilawaContentGrid(
                  padding: EdgeInsets.fromLTRB(
                    tokens.spaceLarge,
                    tokens.spaceLarge,
                    tokens.spaceLarge,
                    bottomPadding,
                  ),
                  targetItemExtent: 180,
                  crossAxisSpacing: tokens.spaceLarge,
                  mainAxisSpacing: tokens.spaceLarge,
                  childAspectRatio: 1.0,
                  itemCount: state.categories.length,
                  itemBuilder: (context, index) {
                    final AthkarCategory category = state.categories[index];
                    return AthkarCategoryCard(
                      name: localizedAthkarCategoryTitle(context, category),
                      icon: category.icon,
                      onTap: () {
                        AthkarDetailsRoute(
                          categoryId: category.id,
                          categoryName: localizedAthkarCategoryTitle(
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
