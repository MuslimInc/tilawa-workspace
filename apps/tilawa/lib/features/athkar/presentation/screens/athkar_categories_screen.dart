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
import '../widgets/athkar_category_card.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/tilawa_back_button.dart';
import 'tasbeeh_screen.dart';

class AthkarCategoriesScreen extends StatelessWidget {
  const AthkarCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AthkarCubit>()..loadCategories(),
      child: Scaffold(
        appBar: AppBar(
          leading: context.canPop() ? const TilawaBackButton() : null,
          title: Text(context.l10n.athkar),
        ),
        body: BlocBuilder<AthkarCubit, AthkarState>(
          builder: (context, state) {
            if (state is AthkarLoading) {
              return const TilawaLoadingIndicator();
            } else if (state is AthkarError) {
              return Center(
                child: Text(
                  state.failure.message ?? 'An unexpected error occurred',
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
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final AthkarCategory category = categories[index];
                  return AthkarCategoryCard(
                    name: category.nameAr,
                    icon: category.icon,
                    onTap: () {
                      if (category.id == TasbeehConstants.categoryId) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const TasbeehScreen(),
                          ),
                        );
                        return;
                      }

                      AthkarDetailsRoute(
                        categoryId: category.id,
                        categoryName: category.nameAr,
                      ).push(context);
                    },
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
