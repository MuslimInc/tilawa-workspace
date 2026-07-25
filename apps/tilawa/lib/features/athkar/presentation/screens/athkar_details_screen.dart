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

import '../cubit/athkar_cubit.dart';
import '../cubit/athkar_state.dart';
import '../widgets/athkar_ambient_background.dart';
import '../widgets/athkar_details_body.dart';

class AthkarDetailsScreen extends StatefulWidget {
  const AthkarDetailsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.source = 'manual',
  });

  final int categoryId;
  final String categoryName;
  final String source;

  @override
  State<AthkarDetailsScreen> createState() => _AthkarDetailsScreenState();
}

class _AthkarDetailsScreenState extends State<AthkarDetailsScreen> {
  int _currentIndex = 0;
  bool _isConfirmingLeave = false;

  @override
  void initState() {
    super.initState();
    getIt<AnalyticsService>().logAthkarReadStart(
      widget.categoryId,
      widget.categoryName,
      source: widget.source,
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return AppReviewSacredFlowScope(
      flow: AppReviewBlockedFlow.athkar,
      child: BlocProvider(
        create: (context) =>
            getIt<AthkarCubit>()..loadAthkar(widget.categoryId),
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
              return Scaffold(
                appBar: TilawaCatalogAppBar(
                  title: widget.categoryName,
                  automaticallyImplyLeading: true,
                  onBackPressed: () => unawaited(_confirmLeave()),
                  actions: [
                    if (state is AthkarItemsLoaded) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.spaceSmall,
                          vertical: tokens.spaceExtraSmall,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: tokens.opacityGlass,
                          ),
                          borderRadius: BorderRadius.circular(
                            tokens.radiusMedium,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: tokens.opacitySubtle,
                            ),
                            width: tokens.borderWidthThin,
                          ),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${state.items.length}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                body: Builder(
                  builder: (context) {
                    return Stack(
                      children: [
                        const Positioned.fill(child: AthkarAmbientBackground()),
                        Positioned.fill(
                          child: switch (state) {
                            AthkarLoading() => const TilawaLoadingIndicator(),
                            AthkarError(:final failure) => TilawaErrorState(
                              icon: Icons.menu_book_rounded,
                              title:
                                  failure.message ??
                                  context.l10n.unexpectedError,
                              retryLabel: context.l10n.retry,
                              onRetry: () {
                                context.read<AthkarCubit>().loadAthkar(
                                  widget.categoryId,
                                );
                              },
                            ),
                            AthkarItemsLoaded(
                              :final items,
                              :final currentCounts,
                            ) =>
                              AthkarDetailsBody(
                                items: items,
                                currentCounts: currentCounts,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentIndex = index;
                                  });
                                },
                              ),
                            _ => const SizedBox.shrink(),
                          },
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
