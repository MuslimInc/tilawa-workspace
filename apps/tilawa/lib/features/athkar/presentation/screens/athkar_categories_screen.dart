import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import '../../../../router/app_router_config.dart';
import '../../domain/entities/athkar_category.dart';
import '../cubit/athkar_cubit.dart';
import '../cubit/athkar_state.dart';
import '../widgets/athkar_category_card.dart';

class AthkarCategoriesScreen extends StatelessWidget {
  const AthkarCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AthkarCubit>()..loadCategories(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.athkar),
          actions: [
            IconButton(
              icon: const Icon(FluentIcons.book_24_regular),
              tooltip: context.l10n.quranReader,
              onPressed: () =>
                  const QuranReaderRoute(surahNumber: 1).push(context),
            ),
          ],
        ),
        body: BlocBuilder<AthkarCubit, AthkarState>(
          builder: (context, state) {
            if (state is AthkarLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AthkarError) {
              return Center(child: Text(state.message));
            } else if (state is AthkarCategoriesLoaded) {
              return GridView.builder(
                padding: EdgeInsets.all(20.r),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.r,
                  mainAxisSpacing: 16.r,
                  childAspectRatio: 0.9,
                ),
                itemCount: state.categories.length,
                itemBuilder: (context, index) {
                  final AthkarCategory category = state.categories[index];
                  return AthkarCategoryCard(
                    category: category,
                    onTap: () {
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
