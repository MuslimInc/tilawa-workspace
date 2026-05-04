import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../helpers/datetime_helper.dart';
import '../../../../shared/widgets/quran_player_widget.dart';
import '../../../../shared/widgets/tilawa_back_button.dart';
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
    return Scaffold(
      appBar: AppBar(
        leading: context.canPop() ? const TilawaBackButton() : null,
        title: Text(context.l10n.listeningHistory),
        actions: [
          BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              if (state.historyList.isNotEmpty) {
                return PopupMenuButton<String>(
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
                          const Icon(
                            Icons.delete_sweep,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 12),
                          Text(context.l10n.clearAll),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<HistoryBloc>().add(
                    const HistoryEvent.refreshHistory(),
                  );
                },
                child: CustomScrollView(
                  slivers: [
                    // Stats card
                    if (state.historyList.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: HistoryStatsCard(
                            totalItems: state.historyList.length,
                            totalListeningTimeMs: state.totalListeningTimeMs,
                          ),
                        ),
                      ),

                    // Search bar
                    if (state.historyList.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: HistorySearchBar(
                            controller: _searchController,
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
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // Content based on state
                    _buildContent(context, state),

                    // Dynamic bottom padding based on player visibility
                    SliverToBoxAdapter(
                      child: SizedBox(height: _calculateBottomPadding(context)),
                    ),
                  ],
                ),
              );
            },
          ),
          const Positioned.fill(child: QuranPlayerWidget()),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, HistoryState state) {
    final tokens = Theme.of(context).tokens;
    switch (state.status) {
      case HistoryStatus.initial:
      case HistoryStatus.loading:
        return SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceMedium,
            vertical: tokens.spaceSmall,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index.isOdd) {
                  return SizedBox(height: tokens.spaceSmall);
                }
                return const TilawaSkeletonListTile(lines: 2);
              },
              childCount: 11, // 5 items + 5 gaps + 1 extra for bottom spacing
            ),
          ),
        );

      case HistoryStatus.error:
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  state.failure?.localizedMessage(context) ??
                      context.l10n.unknownError,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<HistoryBloc>().add(
                      const HistoryEvent.loadAllHistory(),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );

      case HistoryStatus.empty:
        if (state.searchQuery.isNotEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(context.l10n.noSearchResults),
                ],
              ),
            ),
          );
        }
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(context.l10n.noHistoryYet),
                const SizedBox(height: 8),
                Text(
                  context.l10n.noHistoryDescription,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        );

      case HistoryStatus.loaded:
        return _buildHistoryList(context, state.filteredList);
    }
  }

  Widget _buildHistoryList(BuildContext context, List<HistoryEntity> history) {
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
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
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  context.read<HistoryBloc>().add(
                    HistoryEvent.deleteHistory(item.id),
                  );
                  ToastUtils.showSuccessToast(context.l10n.historyDeleted);
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

  /// Calculates the bottom padding needed for the scroll view.
  /// When the player is visible, adds the player height plus safe area.
  /// Otherwise, just adds the safe area padding.
  double _calculateBottomPadding(BuildContext context) {
    final audioPlayerState = context.read<AudioPlayerBloc>().state;
    final safeAreaPadding = MediaQuery.paddingOf(context).bottom;

    if (audioPlayerState.shouldShowBottomPlayer) {
      // Player is visible: add collapsed height + safe area + small extra
      return QuranPlayerWidget.collapsedHeight(context) +
          safeAreaPadding; // Extra spacing
    }

    // Player not visible: just safe area
    return safeAreaPadding;
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
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: Text(
              context.l10n.clearAll,
              style: const TextStyle(color: Colors.red),
            ),
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
