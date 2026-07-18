import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';

import '../cubit/radio_cubit.dart';
import '../pages/radio_home_page.dart';
import 'radio_playback_actions.dart';

class RadioHomeScope extends StatelessWidget {
  const RadioHomeScope({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<RadioCubit>()
            ..load(language: RadioPlaybackActions.apiLanguage(context)),
      child: child ?? const RadioHomePage(),
    );
  }
}
