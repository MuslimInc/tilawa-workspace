import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:tilawa/screens/app_shell_nav_destinations.dart';
import 'package:tilawa/screens/cubit/main_screen_cubit.dart';

/// Switches to the Reciters tab when [MainScreenCubit] is available.
///
/// Falls back to no-op when Home is rendered outside the app shell (e.g.
/// isolated widget tests) so quick-action taps never throw provider errors.
void openHomeRecitersTab(BuildContext context) {
  final MainScreenCubit? cubit = _readMainScreenCubit(context);
  cubit?.selectTab(kAppShellRecitersTabIndex);
}

/// Switches to the Settings / profile tab when [MainScreenCubit] is available.
void openHomeSettingsTab(BuildContext context) {
  final MainScreenCubit? cubit = _readMainScreenCubit(context);
  cubit?.selectTab(kAppShellSettingsTabIndex);
}

MainScreenCubit? _readMainScreenCubit(BuildContext context) {
  try {
    return context.read<MainScreenCubit>();
  } on ProviderNotFoundException {
    return null;
  }
}
