import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/shared/widgets/tilawa_back_button.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../cubit/tasbeeh_cubit.dart';
import '../cubit/tasbeeh_state.dart';
import '../models/tasbeeh_counting_session.dart';
import '../widgets/athkar_ambient_background.dart';
import '../widgets/tasbeeh/tasbeeh_counting_actions.dart';
import '../widgets/tasbeeh/tasbeeh_create_view.dart';
import '../widgets/tasbeeh/tasbeeh_ephemeral_counting_view.dart';
import '../widgets/tasbeeh/tasbeeh_history_view.dart';
import '../widgets/tasbeeh/tasbeeh_layout_widgets.dart';
import '../widgets/tasbeeh/tasbeeh_saved_dhikr_counting_view.dart';

class TasbeehScreen extends StatelessWidget {
  const TasbeehScreen({super.key, this.cubit});

  final TasbeehCubit? cubit;

  @override
  Widget build(BuildContext context) {
    const child = _TasbeehView();
    if (cubit != null) {
      return BlocProvider<TasbeehCubit>.value(value: cubit!, child: child);
    }
    return BlocProvider<TasbeehCubit>(
      create: (_) => getIt<TasbeehCubit>()..loadSavedDhikr(),
      child: child,
    );
  }
}

class _TasbeehView extends StatelessWidget {
  const _TasbeehView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasbeehCubit, TasbeehState>(
      builder: (context, state) {
        final cubit = context.read<TasbeehCubit>();
        final TasbeehCountingSession? session = state.countingSession;

        late final Widget content;
        Widget? bottomActions;

        switch (state.viewMode) {
          case TasbeehViewMode.counting:
            final TasbeehEphemeralCountingSession ephemeral =
                session as TasbeehEphemeralCountingSession? ??
                TasbeehEphemeralCountingSession(count: state.ephemeralCount);
            content = TasbeehEphemeralCountingView(
              cubit: cubit,
              session: ephemeral,
            );
            bottomActions = TasbeehEphemeralCountingActions(
              cubit: cubit,
              session: ephemeral,
              state: state,
            );
          case TasbeehViewMode.selectedCounting:
            switch (session) {
              case TasbeehSavedDhikrCountingSession saved:
                content = TasbeehSavedDhikrCountingView(
                  cubit: cubit,
                  session: saved,
                );
                bottomActions = TasbeehSavedDhikrCountingActions(
                  cubit: cubit,
                  session: saved,
                  state: state,
                );
              default:
                content = const SizedBox.shrink();
            }
          case TasbeehViewMode.create:
            content = TasbeehCreateView(cubit: cubit, state: state);
            bottomActions = TasbeehCreateActions(cubit: cubit, state: state);
          case TasbeehViewMode.history:
            content = TasbeehHistoryView(cubit: cubit, state: state);
        }

        final savedSession = state.activeSavedDhikr;
        final bool isSubView =
            state.viewMode == TasbeehViewMode.create ||
            state.viewMode == TasbeehViewMode.history ||
            state.viewMode == TasbeehViewMode.selectedCounting;

        return Scaffold(
          appBar: TilawaCatalogAppBar(
            preferredHeight: TilawaAppBarConfig.catalogTitleOnlyHeight(context),
            title: savedSession != null &&
                    state.viewMode == TasbeehViewMode.selectedCounting
                ? savedSession.text
                : context.l10n.tasbeehCategory,
            leading: isSubView
                ? TilawaBackButton(
                    compact: true,
                    onPressed: switch (state.viewMode) {
                      TasbeehViewMode.selectedCounting => cubit.showHistoryView,
                      _ => cubit.startEphemeralCounting,
                    },
                  )
                : context.canPop()
                ? TilawaBackButton(
                    compact: true,
                    onPressed: () => context.pop(),
                  )
                : null,
          ),
          body: Stack(
            children: [
              const Positioned.fill(child: AthkarAmbientBackground()),
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        child: content,
                      ),
                    ),
                    if (bottomActions != null)
                      TasbeehBottomActionArea(child: bottomActions),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
