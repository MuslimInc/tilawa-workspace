import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tilawa/core/extensions.dart';
import '../../../../helpers/datetime_helper.dart';
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
                          const Icon(Icons.delete_sweep, size: 20),
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
      body: BlocBuilder<HistoryBloc, HistoryState>(
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, HistoryState state) {
    switch (state.status) {
      case HistoryStatus.initial:
      case HistoryStatus.loading:
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );

      case HistoryStatus.error:
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(state.errorMessage, textAlign: TextAlign.center),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.historyDeleted),
                      duration: const Duration(seconds: 2),
                    ),
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
    // TODO: Navigate to player with this surah
    // context.push('/player', extra: {
    //   'surahId': history.surahId,
    //   'reciterId': history.reciterId,
    //   'moshafId': history.moshafId,
    //   'startPosition': history.lastPositionMs,
    // });
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
