import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../core/di/injection.dart';
import '../bloc/daily_guidance_cubit.dart';
import '../bloc/daily_guidance_state.dart';
import '../widgets/daily_guidance_card.dart';

class DailyGuidanceScreen extends StatelessWidget {
  const DailyGuidanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<DailyGuidanceCubit>();
        unawaited(cubit.loadTodayGuidance());
        return cubit;
      },
      child: Scaffold(
        appBar: const TilawaAppBar(
          title: 'Daily Guidance',
        ),
        body: BlocBuilder<DailyGuidanceCubit, DailyGuidanceState>(
          builder: (context, state) {
            if (state is DailyGuidanceLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is DailyGuidanceError) {
              return Center(child: Text('Error: ${state.message}'));
            } else if (state is DailyGuidanceLoaded) {
              final item = state.todayItem;
              if (item == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'No guidance available for today.',
                          style: context.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<DailyGuidanceCubit>().loadTodayGuidance();
                },
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    DailyGuidanceCard(item: item),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      title: const Text('Enable Daily Notifications'),
                      value: state.preferences.enabled,
                      onChanged: (val) {
                        unawaited(
                          context.read<DailyGuidanceCubit>().toggleFeature(
                            enable: val,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
