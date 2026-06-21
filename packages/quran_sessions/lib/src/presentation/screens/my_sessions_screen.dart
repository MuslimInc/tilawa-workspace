import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../failure_ui/quran_sessions_failure_ui.dart';
import '../blocs/my_sessions/my_sessions_bloc.dart';
import '../blocs/my_sessions/my_sessions_event.dart';
import '../blocs/my_sessions/my_sessions_state.dart';
import '../widgets/session_card.dart';

class MySessionsScreen extends StatefulWidget {
  const MySessionsScreen({
    super.key,
    required this.studentId,
    this.resolveTeacherName,
  });

  final String studentId;

  /// Optional callback to resolve a teacher's display name from their ID.
  /// When provided, teacher names are shown on session cards.
  final String? Function(String teacherId)? resolveTeacherName;

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
      appBar: AppBar(title: const Text('جلساتي')),
      body: BlocConsumer<MySessionsBloc, MySessionsState>(
        listener: (context, state) {
          if (state is MySessionsSuccess && state.lastSubmittedReview != null) {
            TilawaFeedback.showToast(
              context,
              message: 'شكراً — تم إرسال تقييمك!',
              variant: TilawaFeedbackVariant.success,
            );
          }
        },
        builder: (context, state) => switch (state) {
          MySessionsInitial() || MySessionsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          MySessionsEmpty() => const Center(
            child: _EmptyState(),
          ),
          MySessionsFailure(:final failure) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(failure.toLocalizedMessage(context)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _reload,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
          MySessionsSuccess(:final upcoming, :final past) => RefreshIndicator(
            onRefresh: () async => _reload(),
            child: CustomScrollView(
              slivers: [
                _SectionHeader(title: 'القادمة (${upcoming.length})'),
                if (upcoming.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('لا توجد جلسات قادمة'),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: upcoming.length,
                    itemBuilder: (context, i) {
                      final session = upcoming[i];
                      return SessionCard(
                        session: session,
                        teacherName: widget.resolveTeacherName?.call(
                          session.teacherId,
                        ),
                        onJoin: () => context.read<MySessionsBloc>().add(
                          SessionJoinRequested(sessionId: session.id),
                        ),
                        onCancel: () => _confirmCancel(session.bookingId),
                      );
                    },
                  ),
                _SectionHeader(title: 'السابقة (${past.length})'),
                if (past.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('لا توجد جلسات سابقة'),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: past.length,
                    itemBuilder: (context, i) {
                      final session = past[i];
                      return SessionCard(
                        session: session,
                        teacherName: widget.resolveTeacherName?.call(
                          session.teacherId,
                        ),
                      );
                    },
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
        title: const Text('إلغاء الجلسة؟'),
        content: const Text('لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('بقاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إلغاء الجلسة'),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد جلسات بعد',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'احجز جلستك الأولى مع أحد معلمينا المعتمدين',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
