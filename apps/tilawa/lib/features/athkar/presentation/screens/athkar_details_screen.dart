import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_blocked_flow.dart';
import 'package:tilawa/features/app_review/presentation/widgets/app_review_sacred_flow_scope.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/athkar_item.dart';
import '../cubit/athkar_cubit.dart';
import '../cubit/athkar_state.dart';
import '../widgets/athkar_ambient_background.dart';
import '../widgets/athkar_details_body.dart';
import '../widgets/athkar_index_sheet.dart';
import '../widgets/athkar_session_bottom_bar.dart';

class AthkarDetailsScreen extends StatefulWidget {
  const AthkarDetailsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.source = 'manual',
    this.restoreProgress = false,
  });

  final int categoryId;
  final String categoryName;
  final String source;
  final bool restoreProgress;

  @override
  State<AthkarDetailsScreen> createState() => _AthkarDetailsScreenState();
}

class _AthkarDetailsScreenState extends State<AthkarDetailsScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _isConfirmingLeave = false;
  bool _didApplyResumeIndex = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    getIt<AnalyticsService>().logAthkarReadStart(
      widget.categoryId,
      widget.categoryName,
      source: widget.source,
    );
  }

  void _applyResumeIndexIfNeeded(AthkarItemsLoaded loaded) {
    if (_didApplyResumeIndex || !widget.restoreProgress) {
      return;
    }
    _didApplyResumeIndex = true;
    final int index = loaded.resumeIndex.clamp(
      0,
      loaded.items.isEmpty ? 0 : loaded.items.length - 1,
    );
    if (index <= 0) {
      _currentIndex = 0;
      return;
    }
    _currentIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }
      _pageController.jumpToPage(index);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _confirmLeave() async {
    if (_isConfirmingLeave) {
      return;
    }
    _isConfirmingLeave = true;
    try {
      final l10n = context.l10n;
      final bool? leave = await showTilawaConfirmDialog(
        context: context,
        title: l10n.athkarLeaveTitle,
        message: l10n.athkarLeaveMessage,
        confirmLabel: l10n.athkarLeaveConfirm,
        cancelLabel: l10n.cancel,
        confirmVariant: TilawaButtonVariant.primary,
      );
      if (leave == true && mounted) {
        context.pop();
      }
    } finally {
      _isConfirmingLeave = false;
    }
  }

  Future<void> _openIndex(List<AthkarItem> items) async {
    final int? selected = await showAthkarIndexSheet(
      context: context,
      items: items,
      currentIndex: _currentIndex,
      categoryName: widget.categoryName,
    );
    if (selected == null || !mounted) {
      return;
    }
    await _pageController.animateToPage(
      selected,
      duration: context.tokens.durationFast,
      curve: Curves.easeInOut,
    );
    if (mounted) {
      setState(() {
        _currentIndex = selected;
      });
    }
  }

  int _safeIndex(int length) {
    if (length <= 0) {
      return 0;
    }
    return _currentIndex.clamp(0, length - 1);
  }

  void _onCountTap({
    required BuildContext context,
    required List<AthkarItem> items,
    required Map<int, int> currentCounts,
  }) {
    if (items.isEmpty) {
      return;
    }
    final AthkarItem item = items[_safeIndex(items.length)];
    final int count = currentCounts[item.id] ?? 0;
    if (count > 0) {
      context.read<AthkarCubit>().decrementCount(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return AppReviewSacredFlowScope(
      flow: AppReviewBlockedFlow.athkar,
      child: BlocProvider(
        create: (context) => getIt<AthkarCubit>()
          ..loadAthkar(
            widget.categoryId,
            restoreProgress: widget.restoreProgress,
          ),
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, _) {
            if (didPop) {
              return;
            }
            unawaited(_confirmLeave());
          },
          child: BlocBuilder<AthkarCubit, AthkarState>(
            builder: (context, state) {
              final AthkarItemsLoaded? loaded = state is AthkarItemsLoaded
                  ? state
                  : null;
              if (loaded != null) {
                _applyResumeIndexIfNeeded(loaded);
              }
              final double progress = loaded == null || loaded.items.isEmpty
                  ? 0
                  : (_currentIndex + 1) / loaded.items.length;

              return Scaffold(
                appBar: TilawaAppBar(
                  title: widget.categoryName,
                  actions: [
                    if (loaded != null)
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: tokens.spaceSmall,
                        ),
                        child: TilawaIconActionButton(
                          icon: Icons.menu_rounded,
                          tooltip: context.l10n.athkarIndexTooltip,
                          semanticLabel: context.l10n.athkarIndexTooltip,
                          backgroundColor: colorScheme.surfaceContainerHighest
                              .withValues(alpha: tokens.opacityGlass),
                          onTap: () => unawaited(_openIndex(loaded.items)),
                        ),
                      ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(tokens.spaceExtraSmall),
                    child: LinearProgressIndicator(
                      value: loaded == null ? null : progress,
                      minHeight: tokens.spaceExtraSmall / 2,
                      backgroundColor: colorScheme.outlineVariant.withValues(
                        alpha: tokens.opacitySubtle,
                      ),
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                body: Stack(
                  children: [
                    const Positioned.fill(child: AthkarAmbientBackground()),
                    Positioned.fill(
                      child: switch (state) {
                        AthkarLoading() => const TilawaLoadingIndicator(),
                        AthkarError(:final failure) => TilawaErrorState(
                          icon: Icons.menu_book_rounded,
                          title:
                              failure.message ?? context.l10n.unexpectedError,
                          retryLabel: context.l10n.retry,
                          onRetry: () {
                            context.read<AthkarCubit>().loadAthkar(
                              widget.categoryId,
                              restoreProgress: widget.restoreProgress,
                            );
                          },
                        ),
                        AthkarItemsLoaded(
                          :final items,
                          :final currentCounts,
                        ) =>
                          Column(
                            children: [
                              Expanded(
                                child: AthkarDetailsBody(
                                  items: items,
                                  currentCounts: currentCounts,
                                  pageController: _pageController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentIndex = index;
                                    });
                                  },
                                ),
                              ),
                              if (items.isNotEmpty)
                                Builder(
                                  builder: (context) {
                                    final int index = _safeIndex(items.length);
                                    final AthkarItem item = items[index];
                                    return AthkarSessionBottomBar(
                                      item: item,
                                      currentCount: currentCounts[item.id] ?? 0,
                                      currentIndex: index,
                                      totalItems: items.length,
                                      onCountTap: () => _onCountTap(
                                        context: context,
                                        items: items,
                                        currentCounts: currentCounts,
                                      ),
                                      onReset: () {
                                        context.read<AthkarCubit>().resetCount(
                                          item.id,
                                        );
                                      },
                                    );
                                  },
                                ),
                            ],
                          ),
                        _ => const SizedBox.shrink(),
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
