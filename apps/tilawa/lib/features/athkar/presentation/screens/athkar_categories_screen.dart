import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router_config.dart';
import '../../domain/constants/tasbeeh_constants.dart';
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
    return BlocProvider(
      create: (context) => getIt<AthkarCubit>()..loadCategories(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.athkar),
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
                  final tokens = Theme.of(context).tokens;
                  final categories = [
                    ...state.categories,
                    AthkarCategory(
                      id: TasbeehConstants.categoryId,
                      nameAr: context.l10n.tasbeehCategory,
                      nameEn: context.l10n.tasbeehCategory,
                      icon: TasbeehConstants.categoryIconName,
                    ),
                  ];

                  return TilawaContentGrid(
                    padding: EdgeInsets.fromLTRB(
                      tokens.spaceLarge,
                      tokens.spaceLarge,
                      tokens.spaceLarge,
                      tokens.spaceLarge,
                    ),
                    targetItemExtent: 180,
                    crossAxisSpacing: tokens.spaceLarge,
                    mainAxisSpacing: tokens.spaceLarge,
                    childAspectRatio: 1.0,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final AthkarCategory category = categories[index];
                      return AthkarCategoryCard(
                        name: _localizedAthkarCategoryTitle(context, category),
                        icon: category.icon,
                        onTap: () {
                          if (category.id == TasbeehConstants.categoryId) {
                            const TasbeehRoute().push(context);
                            return;
                          }

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
      ),
    );
  }
}
