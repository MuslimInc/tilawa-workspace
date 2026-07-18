import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';

import '../cubit/reels_cubit.dart';
import '../cubit/saved_reels_cubit.dart';
import '../pages/reels_feed_page.dart';
import '../pages/saved_reels_page.dart';

class ReelsFeedScope extends StatelessWidget {
  const ReelsFeedScope({super.key, this.initialReelId});

  final int? initialReelId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReelsCubit>(),
      child: ReelsFeedPage(initialReelId: initialReelId),
    );
  }
}

class SavedReelsScope extends StatelessWidget {
  const SavedReelsScope({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SavedReelsCubit>(),
      child: const SavedReelsPage(),
    );
  }
}
