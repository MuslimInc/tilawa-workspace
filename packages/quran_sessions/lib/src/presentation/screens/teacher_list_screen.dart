import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/teacher_list/teacher_list_bloc.dart';
import '../blocs/teacher_list/teacher_list_event.dart';
import '../blocs/teacher_list/teacher_list_state.dart';
import '../widgets/teacher_card.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({super.key});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<TeacherListBloc>().add(const LoadTeachersRequested());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TeacherListBloc>().add(const LoadMoreTeachersRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find a Teacher')),
      body: BlocBuilder<TeacherListBloc, TeacherListState>(
        builder: (context, state) => switch (state) {
          TeacherListInitial() || TeacherListLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          TeacherListEmpty(:final activeSpecialization) => _EmptyView(
            specialization: activeSpecialization,
          ),
          TeacherListFailure(:final failure) => _ErrorView(
            failure: failure.toString(),
            onRetry: _retry,
          ),
          TeacherListSuccess(
            :final teachers,
            :final isLoadingMore,
          ) =>
            RefreshIndicator(
              onRefresh: () async => _retry(),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: teachers.length + (isLoadingMore ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == teachers.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return TeacherCard(
                    teacher: teachers[i],
                    onTap: () => _onTeacherTapped(teachers[i].id),
                  );
                },
              ),
            ),
        },
      ),
    );
  }

  void _retry() =>
      context.read<TeacherListBloc>().add(const LoadTeachersRequested());

  void _onTeacherTapped(String teacherId) {
    // Navigation handled by host app router; package exposes route constants.
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({this.specialization});
  final String? specialization;

  @override
  Widget build(BuildContext context) {
    final label = specialization != null
        ? 'No teachers found for "$specialization"'
        : 'No teachers available right now';
    return Center(child: Text(label));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.failure, required this.onRetry});
  final String failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Something went wrong'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
