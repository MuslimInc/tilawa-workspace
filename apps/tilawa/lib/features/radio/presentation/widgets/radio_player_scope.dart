import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';

import '../cubit/radio_cubit.dart';
import '../pages/radio_player_page.dart';
import 'radio_playback_actions.dart';

/// Provides [RadioCubit] for the full player route.
class RadioPlayerScope extends StatelessWidget {
  const RadioPlayerScope({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<RadioCubit>()
            ..load(language: RadioPlaybackActions.apiLanguage(context)),
      child: RadioPlayerPage(stationId: stationId),
    );
  }
}
