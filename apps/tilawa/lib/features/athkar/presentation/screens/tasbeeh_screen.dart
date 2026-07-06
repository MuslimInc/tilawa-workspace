import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/layout/list_scroll_bottom_padding.dart';
import 'package:tilawa/shared/widgets/tilawa_back_button.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/tasbeeh_dhikr.dart';
import '../../domain/entities/tasbeeh_layout_mode.dart';
import '../cubit/tasbeeh_cubit.dart';
import '../cubit/tasbeeh_state.dart';
import '../models/tasbeeh_counting_session.dart';
import '../widgets/athkar_ambient_background.dart';
import '../widgets/tasbeeh/tasbeeh_counting_actions.dart';
import '../widgets/tasbeeh/tasbeeh_create_view.dart';
import '../widgets/tasbeeh/tasbeeh_ephemeral_counting_view.dart';
import '../widgets/tasbeeh/tasbeeh_home_view.dart';
import '../widgets/tasbeeh/tasbeeh_layout_widgets.dart';
import '../widgets/tasbeeh/tasbeeh_reminder_sheet.dart';
import '../widgets/tasbeeh/tasbeeh_saved_dhikr_counting_view.dart';

class TasbeehScreen extends StatelessWidget {
  const TasbeehScreen({super.key, this.cubit, this.initialDhikrId});

  final TasbeehCubit? cubit;
  final String? initialDhikrId;

  @override
  Widget build(BuildContext context) {
    const child = _TasbeehView();
    if (cubit != null) {
      return BlocProvider<TasbeehCubit>.value(value: cubit!, child: child);
    }
    return BlocProvider<TasbeehCubit>(
      create: (_) =>
          getIt<TasbeehCubit>()..loadSavedDhikr(openDhikrId: initialDhikrId),
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
          case TasbeehViewMode.home:
            if (state.status == TasbeehStatus.loading) {
              content = const Center(child: CircularProgressIndicator());
            } else {
              content = TasbeehHomeView(cubit: cubit, state: state);
              bottomActions = TasbeehHomeActions(cubit: cubit);
            }
          case TasbeehViewMode.quickCount:
            final TasbeehEphemeralCountingSession ephemeral =
                session as TasbeehEphemeralCountingSession? ??
                TasbeehEphemeralCountingSession(count: state.ephemeralCount);
            content = TasbeehQuickCountView(
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
        }

        final savedSession = state.activeSavedDhikr;
        final bool isSubView = state.viewMode != TasbeehViewMode.home;
        final String appBarTitle = switch (state.viewMode) {
          TasbeehViewMode.selectedCounting when savedSession != null =>
            savedSession.text,
          TasbeehViewMode.quickCount => context.l10n.tasbeehQuickCountTitle,
          TasbeehViewMode.create => context.l10n.tasbeehAddNewOptionTitle,
          _ => context.l10n.tasbeehCategory,
        };
        final Widget? appBarLeading = isSubView
            ? TilawaBackButton(
                compact: true,
                onPressed: cubit.showHomeView,
              )
            : Navigator.canPop(context)
            ? TilawaBackButton(
                compact: true,
                onPressed: () => context.pop(),
              )
            : null;
        final List<Widget>? appBarActions = _TasbeehAppBarActions(
          cubit: cubit,
          state: state,
          savedSession: savedSession,
        ).build(context);

        return Scaffold(
          appBar: TilawaCatalogAppBar(
            preferredHeight: TilawaCatalogAppBar.resolvePreferredHeight(
              context,
              title: appBarTitle,
              leading: appBarLeading,
              actions: appBarActions,
            ),
            title: appBarTitle,
            leading: appBarLeading,
            actions: appBarActions,
          ),
          body: Stack(
            children: [
              const Positioned.fill(child: AthkarAmbientBackground()),
              SafeArea(
                // The pinned TilawaBottomActionInset owns the bottom clearance
                // (floatingBottomPadding + extraBottom); a bottom SafeArea here
                // would double-count the device inset. Matches the auth screens.
                bottom: false,
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
                      TilawaBottomActionInset(
                        top: Theme.of(context).tokens.spaceSmall,
                        extraBottom: bottomActionExtraInset(context),
                        child: bottomActions,
                      ),
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

class _TasbeehAppBarActions {
  const _TasbeehAppBarActions({
    required this.cubit,
    required this.state,
    required this.savedSession,
  });

  final TasbeehCubit cubit;
  final TasbeehState state;
  final TasbeehDhikr? savedSession;

  List<Widget>? build(BuildContext context) {
    return switch (state.viewMode) {
      TasbeehViewMode.home when state.savedDhikr.isNotEmpty => [
        _LayoutToggleButton(cubit: cubit, layoutMode: state.layoutMode),
        _ClearAllButton(cubit: cubit, itemCount: state.savedDhikr.length),
      ],
      TasbeehViewMode.home => [
        _LayoutToggleButton(cubit: cubit, layoutMode: state.layoutMode),
      ],
      TasbeehViewMode.selectedCounting when savedSession != null => [
        TilawaIconActionButton(
          icon: savedSession!.reminderEnabled
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
          tooltip: context.l10n.tasbeehReminderAction,
          onTap: () => showTasbeehReminderSheet(
            context: context,
            cubit: cubit,
            dhikr: savedSession!,
          ),
        ),
      ],
      _ => null,
    };
  }
}

class _LayoutToggleButton extends StatelessWidget {
  const _LayoutToggleButton({
    required this.cubit,
    required this.layoutMode,
  });

  final TasbeehCubit cubit;
  final TasbeehLayoutMode layoutMode;

  @override
  Widget build(BuildContext context) {
    final bool isGrid = layoutMode == TasbeehLayoutMode.grid;
    return TilawaIconActionButton(
      icon: isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
      tooltip: isGrid
          ? context.l10n.tasbeehShowAsList
          : context.l10n.tasbeehShowAsGrid,
      onTap: cubit.toggleLayoutMode,
    );
  }
}

class _ClearAllButton extends StatelessWidget {
  const _ClearAllButton({required this.cubit, required this.itemCount});

  final TasbeehCubit cubit;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return TilawaIconActionButton(
      icon: Icons.delete_sweep_rounded,
      tooltip: context.l10n.tasbeehClearAllTitle,
      onTap: () async {
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) =>
              TasbeehClearAllConfirmationDialog(itemCount: itemCount),
        );
        if (confirmed == true) {
          await cubit.clearAllSavedDhikr();
        }
      },
    );
  }
}
