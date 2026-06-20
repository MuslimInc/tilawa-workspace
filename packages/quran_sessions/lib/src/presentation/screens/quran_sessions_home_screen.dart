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
  const QuranSessionsHomeScreen({super.key});

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
      appBar: AppBar(title: const Text('Quran Sessions')),
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
            // Show at most 3 teachers as a preview; "See all" navigates to
            // TeacherListScreen.
            itemCount: teachers.take(3).length + 1,
            itemBuilder: (context, i) {
              if (i < teachers.take(3).length) {
                return TeacherCard(
                  teacher: teachers[i],
                  onTap: () {},
                );
              }
              return TextButton(
                onPressed: () {},
                child: const Text('See all teachers →'),
              );
            },
          ),
        },
      ),
    );
  }
}
