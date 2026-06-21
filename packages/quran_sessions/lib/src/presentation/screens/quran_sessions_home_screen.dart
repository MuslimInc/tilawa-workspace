import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../failure_ui/quran_sessions_failure_ui.dart';
import '../blocs/teacher_list/teacher_list_bloc.dart';
import '../blocs/teacher_list/teacher_list_event.dart';
import '../blocs/teacher_list/teacher_list_state.dart';
import '../widgets/teacher_card.dart';

/// Feature entry point — shows a compact teacher list with a "See all" link
/// and the user's next upcoming session (if any).
class QuranSessionsHomeScreen extends StatefulWidget {
  const QuranSessionsHomeScreen({
    super.key,
    this.onSeeAllTeachers,
    this.onTeacherTapped,
    this.onMySessions,
    this.onBecomeTeacher,
  });

  final VoidCallback? onSeeAllTeachers;
  final void Function(String teacherId)? onTeacherTapped;
  final VoidCallback? onMySessions;

  /// Called when user taps "أريد أن أصبح محفظًا".
  final VoidCallback? onBecomeTeacher;

  @override
  State<QuranSessionsHomeScreen> createState() =>
      _QuranSessionsHomeScreenState();
}

class _QuranSessionsHomeScreenState extends State<QuranSessionsHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TeacherListBloc>().add(const LoadTeachersRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعلم قراءة القرآن'),
        actions: [
          if (widget.onMySessions != null)
            TextButton(
              onPressed: widget.onMySessions,
              child: const Text('جلساتي'),
            ),
        ],
      ),
      body: BlocBuilder<TeacherListBloc, TeacherListState>(
        builder: (context, state) => switch (state) {
          TeacherListInitial() || TeacherListLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          TeacherListEmpty() => const Center(
            child: Text('No teachers available yet'),
          ),
          TeacherListFailure(:final failure) => Center(
            child: Text(failure.toLocalizedMessage(context)),
          ),
          TeacherListSuccess(:final teachers) => ListView.builder(
            padding: const EdgeInsets.all(16),
            // Teachers preview (max 3) + "See all" + "Become a Teacher" card.
            itemCount: teachers.take(3).length + 2,
            itemBuilder: (context, i) {
              final preview = teachers.take(3).toList();
              if (i < preview.length) {
                return TeacherCard(
                  teacher: preview[i],
                  onTap: () => widget.onTeacherTapped?.call(preview[i].id),
                );
              }
              if (i == preview.length) {
                return TextButton(
                  onPressed: widget.onSeeAllTeachers,
                  child: const Text('عرض جميع المعلمين ←'),
                );
              }
              // "Become a Teacher" card at the bottom.
              return _BecomeTeacherCard(onTap: widget.onBecomeTeacher);
            },
          ),
        },
      ),
    );
  }
}

// ── Become a Teacher card ─────────────────────────────────────────────────────

class _BecomeTeacherCard extends StatelessWidget {
  const _BecomeTeacherCard({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Card(
        color: scheme.secondaryContainer,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 36,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أريد أن أصبح محفظًا',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: scheme.onSecondaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'انضم إلى نخبة المعلمين المعتمدين على تلاوة',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSecondaryContainer.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: scheme.onSecondaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
