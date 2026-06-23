import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/home_athkar_compact_cubit.dart';
import '../cubit/home_athkar_compact_state.dart';
import '../cubit/home_listening_resume_cubit.dart';
import '../cubit/home_listening_resume_state.dart';
import '../cubit/home_primary_action_cubit.dart';
import '../cubit/home_primary_action_state.dart';
import '../cubit/home_quran_resume_cubit.dart';
import '../cubit/home_quran_resume_state.dart';
import 'home_primary_action_card.dart';

/// Featured resume surface directly under the Home hero.
class HomePrimaryActionZone extends StatelessWidget {
  const HomePrimaryActionZone({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomePrimaryActionCubit, HomePrimaryActionState>(
      builder: (context, state) => HomePrimaryActionCard(state: state),
    );
  }
}

/// Keeps [HomePrimaryActionCubit] aligned with resume source cubits.
class HomePrimaryActionSyncListener extends StatelessWidget {
  const HomePrimaryActionSyncListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<HomeQuranResumeCubit, HomeQuranResumeState>(
          listener: _recompute,
        ),
        BlocListener<HomeListeningResumeCubit, HomeListeningResumeState>(
          listener: _recompute,
        ),
        BlocListener<HomeAthkarCompactCubit, HomeAthkarCompactState>(
          listener: _recompute,
        ),
      ],
      child: child,
    );
  }

  void _recompute(BuildContext context, Object? _) {
    context.read<HomePrimaryActionCubit>().recompute(
      quran: context.read<HomeQuranResumeCubit>().state,
      listening: context.read<HomeListeningResumeCubit>().state,
      athkar: context.read<HomeAthkarCompactCubit>().state,
    );
  }
}
