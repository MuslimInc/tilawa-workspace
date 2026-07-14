import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../helpers/datetime_helper.dart';
import '../../../../shared/widgets/quran_player_widget.dart';
import '../../../audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../domain/entities/history_entity.dart';
import '../bloc/history_bloc.dart';
import '../widgets/history_card.dart';
import '../widgets/history_search_bar.dart';
import '../widgets/history_stats_card.dart';

/// Screen for displaying listening history.
///
/// NOTE: This screen expects a [HistoryBloc] to be provided in the widget tree.
/// The bloc is provided by [HistoryRoute] in the router configuration.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Note: The HistoryRoute already dispatches loadAllHistory event when creating the bloc.
  // No need to dispatch it again in initState.

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = context.keyboardInset;

    return BlocBuilder<HistoryBloc, HistoryState>(
      buildWhen: (previous, current) =>
          previous.historyList.isEmpty != current.historyList.isEmpty,
      builder: (context, state) {
        final bool hasHistory = state.historyList.isNotEmpty;
        final PreferredSizeWidget appBar = hasHistory
            ? TilawaCatalogAppBar(
                title: context.l10n.listeningHistory,
                leading: TilawaAppBarChrome.catalogBackButton(
                  context: context,
                  onPressed: () => context.pop(),
                ),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'clear_all') {
                        _showClearAllDialog(context);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'clear_all',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_sweep,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Text(context.l10n.clearAll),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                bottomContentHeight: Theme.of(
                  context,
                ).componentTokens.searchField.height,
                bottomContent: HistorySearchBar(
                  controller: _searchController,
                  scrollPadding: EdgeInsets.only(bottom: keyboardInset + 24),
                  onChanged: (query) {
                    context.read<HistoryBloc>().add(
                      HistoryEvent.searchHistory(query),
                    );
                  },
                  onClear: () {
                    _searchController.clear();
                    context.read<HistoryBloc>().add(
                      const HistoryEvent.clearSearch(),
                    );
                  },
                ),
              )
            : TilawaCatalogAppBar.titleOnly(
                title: context.l10n.listeningHistory,
              );

        return TilawaShellChildScaffold(
          appBar: appBar,
          body: Stack(
            children: [
              BlocBuilder<HistoryBloc, HistoryState>(
                builder: (context, state) {
                  final tokens = Theme.of(context).tokens;
                  return TilawaRefreshIndicator(
                    onRefresh: () async {
                      context.read<HistoryBloc>().add(
                        const HistoryEvent.refreshHistory(),
                      );
                    },
                    child: CustomScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        // Stats card
                        if (state.historyList.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(tokens.spaceLarge),
                              child: HistoryStatsCard(
                                totalItems: state.historyList.length,
                                totalListeningTimeMs:
                                    state.totalListeningTimeMs,
                              ),
                            ),
                          ),

                        SliverToBoxAdapter(
                          child: SizedBox(height: tokens.spaceLarge),
                        ),

                        // Content based on state
                        _buildContent(context, state),

                        // Dynamic bottom padding based on player visibility
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: _calculateBottomPadding(context),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, HistoryState state) {
    switch (state.status) {
      case HistoryStatus.initial:
      case HistoryStatus.loading:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: TilawaLoadingIndicator(),
        );

      case HistoryStatus.error:
        return SliverFillRemaining(
          child: TilawaErrorState(
            icon: Icons.error_outline,
            title:
                state.failure?.localizedMessage(context) ??
                context.l10n.unknownError,
            retryLabel: context.l10n.retry,
            onRetry: () {
              context.read<HistoryBloc>().add(
                const HistoryEvent.loadAllHistory(),
              );
            },
          ),
        );

      case HistoryStatus.empty:
        if (state.searchQuery.isNotEmpty) {
          return SliverFillRemaining(
            child: TilawaEmptyState(
              icon: Icons.search_off_rounded,
              title: context.l10n.noSearchResults,
            ),
          );
        }
        return SliverFillRemaining(
          child: TilawaEmptyState(
            icon: Icons.history_rounded,
            title: context.l10n.noHistoryYet,
            subtitle: context.l10n.noHistoryDescription,
          ),
        );

      case HistoryStatus.loaded:
        return _buildHistoryList(context, state.filteredList);
    }
  }

  Widget _buildHistoryList(BuildContext context, List<HistoryEntity> history) {
    final tokens = Theme.of(context).tokens;
    // Group history by date
    final Map<String, List<HistoryEntity>> groupedHistory = {};

    for (final item in history) {
      final String dateKey = _getDateKey(context, item.playedAt);
      groupedHistory.putIfAbsent(dateKey, () => []);
      groupedHistory[dateKey]!.add(item);
    }

    final List<String> dateKeys = groupedHistory.keys.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final String dateKey = dateKeys[index];
        final List<HistoryEntity> items = groupedHistory[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceLarge,
                vertical: tokens.spaceSmall,
              ),
              child: Text(
                dateKey,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            // History items for this date
            ...items.map(
              (item) => Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Theme.of(context).colorScheme.error,
                  // Directional so the icon sits on the reveal side in RTL too.
                  alignment: AlignmentDirectional.centerEnd,
                  padding: EdgeInsets.symmetric(
                    horizontal: Theme.of(context).tokens.spaceLarge,
                  ),
                  child: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
                onDismissed: (_) {
                  context.read<HistoryBloc>().add(
                    HistoryEvent.deleteHistory(item.id),
                  );
                  TilawaFeedback.showToast(
                    context,
                    message: context.l10n.historyDeleted,
                    variant: TilawaFeedbackVariant.success,
                  );
                },
                child: HistoryCard(
                  history: item,
                  onTap: () => _onHistoryTap(context, item),
                ),
              ),
            ),
          ],
        );
      }, childCount: dateKeys.length),
    );
  }

  double _calculateBottomPadding(BuildContext context) {
    if (context.isKeyboardVisible) {
      // Shell already resized; mini-player is hidden while the IME is open.
      return Theme.of(context).tokens.spaceSmall;
    }
    final audioPlayerState = context.read<AudioPlayerBloc>().state;
    if (audioPlayerState.shouldShowBottomPlayer) {
      return QuranPlayerWidget.collapsedFootprint(context);
    }
    return context.floatingBottomPadding;
  }

  String _getDateKey(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return context.l10n.today;
    } else if (dateOnly == yesterday) {
      return context.l10n.yesterday;
    } else if (now.difference(date).inDays < 7) {
      return DateTimeHelper.formatDayOfWeek(date);
    } else {
      return DateTimeHelper.formatDate(date);
    }
  }

  void _onHistoryTap(BuildContext context, HistoryEntity history) {
    final audio = AudioEntity(
      id: history.audioUrl,
      title: history.surahName,
      url: history.audioUrl,
      duration: history.duration,
      artist: history.reciterName,
      album: history.moshafName,
      extras: {
        'surahId': history.surahId,
        'reciterId': history.reciterId,
        'moshafId': history.moshafId,
      },
    );

    context.read<AudioPlayerBloc>().add(
      AudioPlayerEvent.playFromQueue(
        [audio],
        0,
        initialPosition: history.lastPosition,
      ),
    );
  }

  Future<void> _showClearAllDialog(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.clearHistory),
        content: Text(context.l10n.clearHistoryConfirmation),
        actions: [
          TilawaButton(
            text: context.l10n.cancel,
            variant: TilawaButtonVariant.ghost,
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          TilawaButton(
            text: context.l10n.clearAll,
            variant: TilawaButtonVariant.danger,
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
          ),
        ],
      ),
    );

    if (!context.mounted) {
      return;
    }

    if (confirmed ?? false) {
      context.read<HistoryBloc>().add(const HistoryEvent.clearAllHistory());
    }
  }
}
