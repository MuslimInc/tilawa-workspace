import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/reel.dart';
import '../../domain/repositories/reels_repository.dart';
import '../cubit/reels_cubit.dart';
import '../cubit/reels_state.dart';
import '../services/reel_player_pool.dart';
import '../utils/reel_category_labels.dart';
import '../widgets/reel_actions_column.dart';
import '../widgets/reel_page.dart';

class ReelsFeedPage extends StatefulWidget {
  const ReelsFeedPage({super.key, this.initialReelId});

  final int? initialReelId;

  @override
  State<ReelsFeedPage> createState() => _ReelsFeedPageState();
}

class _ReelsFeedPageState extends State<ReelsFeedPage> {
  late final PageController _pageController;
  late final ReelPlayerPool _pool;
  bool _jumpedToInitial = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pool = ReelPlayerPool();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final cubit = context.read<ReelsCubit>();
    cubit.load(
      language: ReelCategoryLabels.apiLanguage(context),
      allLabel: context.l10n.reelsCategoryAll,
      categoryLabels: ReelCategoryLabels.map(context),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pool.dispose();
    super.dispose();
  }

  Future<void> _syncPool(ReelsState state) async {
    if (state.status != ReelsStatus.ready || state.reels.isEmpty) return;
    await _pool.syncFeed(state.reels, state.currentIndex);
    if (!mounted) return;

    if (!_jumpedToInitial && widget.initialReelId != null) {
      final idx = state.reels.indexWhere((r) => r.id == widget.initialReelId);
      if (idx >= 0) {
        _jumpedToInitial = true;
        _pageController.jumpToPage(idx);
        context.read<ReelsCubit>().onPageChanged(idx);
        await _pool.setIndex(idx);
      }
    }
  }

  Future<void> _onReact(Reel reel) async {
    final picked = await showReelReactionPicker(context);
    if (picked == null || !mounted) return;
    await context.read<ReelsCubit>().react(reel.id, picked);
  }

  Future<void> _onMore(Reel reel) async {
    final l10n = context.l10n;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.bookmark_outline),
                title: Text(l10n.reelsSavedTitle),
                onTap: () => Navigator.pop(ctx, 'saved'),
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: Text(l10n.reelsShareLink),
                onTap: () => Navigator.pop(ctx, 'link'),
              ),
              ListTile(
                leading: const Icon(Icons.video_file_outlined),
                title: Text(l10n.reelsShareFile),
                onTap: () => Navigator.pop(ctx, 'file'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'saved':
        unawaited(const SavedReelsRoute().push<void>(context));
      case 'link':
        await context.read<ReelsCubit>().share(
          reel,
          mode: ReelShareMode.link,
        );
      case 'file':
        await context.read<ReelsCubit>().share(
          reel,
          mode: ReelShareMode.file,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocConsumer<ReelsCubit, ReelsState>(
          listenWhen: (p, c) =>
              p.reels != c.reels ||
              p.currentIndex != c.currentIndex ||
              p.status != c.status,
          listener: (context, state) => _syncPool(state),
          builder: (context, state) {
            return Stack(
              children: [
                switch (state.status) {
                  ReelsStatus.initial || ReelsStatus.loading => const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                  ReelsStatus.error => _MessageState(
                    message: l10n.reelsLoadError,
                    actionLabel: l10n.reelsRetry,
                    onAction: _load,
                  ),
                  ReelsStatus.empty => _MessageState(
                    message: l10n.reelsEmpty,
                    actionLabel: l10n.reelsRetry,
                    onAction: _load,
                  ),
                  ReelsStatus.ready => PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    allowImplicitScrolling: true,
                    itemCount: state.reels.length,
                    onPageChanged: (i) {
                      context.read<ReelsCubit>().onPageChanged(i);
                      unawaited(_pool.setIndex(i));
                    },
                    itemBuilder: (context, index) {
                      final reel = state.reels[index];
                      return ListenableBuilder(
                        listenable: _pool,
                        builder: (context, _) {
                          return ReelPage(
                            key: ValueKey(reel.id),
                            reel: reel,
                            pool: _pool,
                            isActive: index == state.currentIndex,
                            showBurst: state.burstReactionReelId == reel.id,
                            onToggleSave: () =>
                                context.read<ReelsCubit>().toggleSave(reel),
                            onReact: () => _onReact(reel),
                            onDoubleTapReact: () => context
                                .read<ReelsCubit>()
                                .doubleTapReact(reel.id),
                            onShare: () => context.read<ReelsCubit>().share(
                              reel,
                              mode: ReelShareMode.link,
                            ),
                            onMore: () => _onMore(reel),
                            onCompleted: () => context
                                .read<ReelsCubit>()
                                .markCompleted(reel.id),
                            onBurstDone: () =>
                                context.read<ReelsCubit>().clearBurst(),
                          );
                        },
                      );
                    },
                  ),
                },

                // Top chrome
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spaceSmall,
                      vertical: tokens.spaceExtraSmall,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).backButtonTooltip,
                            ),
                            Expanded(
                              child: Text(
                                l10n.reelsTitle,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  const SavedReelsRoute().push<void>(context),
                              icon: const Icon(
                                Icons.bookmark_outline,
                                color: Colors.white,
                              ),
                              tooltip: l10n.reelsSavedTitle,
                            ),
                          ],
                        ),
                        if (state.categories.isNotEmpty)
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(
                                horizontal: tokens.spaceSmall,
                              ),
                              itemCount: state.categories.length,
                              separatorBuilder: (_, _) =>
                                  SizedBox(width: tokens.spaceExtraSmall),
                              itemBuilder: (context, i) {
                                final cat = state.categories[i];
                                final selected =
                                    state.selectedCategoryId == cat.id;
                                return FilterChip(
                                  selected: selected,
                                  label: Text(cat.label),
                                  onSelected: (_) => context
                                      .read<ReelsCubit>()
                                      .selectCategory(cat.id),
                                  selectedColor: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  backgroundColor: Colors.white24,
                                  labelStyle: TextStyle(
                                    color: selected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer
                                        : Colors.white,
                                  ),
                                  side: BorderSide.none,
                                  showCheckmark: false,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
            SizedBox(height: tokens.spaceMedium),
            TilawaButton(onPressed: onAction, text: actionLabel),
          ],
        ),
      ),
    );
  }
}
