import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../failure_ui/quran_sessions_failure_ui.dart';
import '../blocs/my_sessions/my_sessions_bloc.dart';
import '../blocs/my_sessions/my_sessions_event.dart';
import '../blocs/my_sessions/my_sessions_state.dart';
import '../widgets/session_card.dart';

class MySessionsScreen extends StatefulWidget {
  const MySessionsScreen({super.key, required this.studentId});

  final String studentId;

  @override
  State<MySessionsScreen> createState() => _MySessionsScreenState();
}

class _MySessionsScreenState extends State<MySessionsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MySessionsBloc>().add(
      MySessionsLoadRequested(studentId: widget.studentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Sessions')),
      body: BlocConsumer<MySessionsBloc, MySessionsState>(
        listener: (context, state) {
          if (state is MySessionsSuccess && state.lastSubmittedReview != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Review submitted — thank you!')),
            );
          }
        },
        builder: (context, state) => switch (state) {
          MySessionsInitial() || MySessionsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          MySessionsEmpty() => const Center(child: Text('No sessions yet')),
          MySessionsFailure(:final failure) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(failure.toLocalizedMessage(context)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _reload,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          MySessionsSuccess(:final upcoming, :final past) => RefreshIndicator(
            onRefresh: () async => _reload(),
            child: CustomScrollView(
              slivers: [
                _SectionHeader(title: 'Upcoming (${upcoming.length})'),
                if (upcoming.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No upcoming sessions'),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: upcoming.length,
                    itemBuilder: (context, i) => SessionCard(
                      session: upcoming[i],
                      onJoin: () => context.read<MySessionsBloc>().add(
                        SessionJoinRequested(sessionId: upcoming[i].id),
                      ),
                      onCancel: () => _confirmCancel(upcoming[i].bookingId),
                    ),
                  ),
                _SectionHeader(title: 'Past (${past.length})'),
                if (past.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No past sessions'),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: past.length,
                    itemBuilder: (context, i) => SessionCard(
                      session: past[i],
                    ),
                  ),
              ],
            ),
          ),
        },
      ),
    );
  }

  void _reload() => context.read<MySessionsBloc>().add(
    MySessionsLoadRequested(studentId: widget.studentId),
  );

  Future<void> _confirmCancel(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel session?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel session'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<MySessionsBloc>().add(
        SessionCancelled(bookingId: bookingId, reason: 'Student cancelled'),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
