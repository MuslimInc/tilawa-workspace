import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/home_layout_mode.dart';
import '../cubit/home_layout_cubit.dart';
import '../cubit/home_layout_state.dart';

/// Switches Home dashboard surfaces between grouped list and card grid.
class HomeLayoutToggleButton extends StatelessWidget {
  const HomeLayoutToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeLayoutCubit, HomeLayoutState>(
      buildWhen: (previous, current) => previous.mode != current.mode,
      builder: (context, state) {
        final bool isGrid = state.mode == HomeLayoutMode.grid;
        return TilawaIconActionButton(
          icon: isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
          tooltip: isGrid
              ? context.l10n.homeExploreShowAsList
              : context.l10n.homeExploreShowAsGrid,
          semanticLabel: isGrid
              ? context.l10n.homeExploreShowAsList
              : context.l10n.homeExploreShowAsGrid,
          onTap: () => context.read<HomeLayoutCubit>().toggleLayoutMode(),
        );
      },
    );
  }
}
