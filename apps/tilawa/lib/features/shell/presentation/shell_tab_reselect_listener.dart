import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/screens/cubit/main_screen_cubit.dart';
import 'package:tilawa/screens/cubit/main_screen_state.dart';

/// Fires [onReselect] when the user re-taps an already active bottom-nav tab.
class ShellTabReselectListener extends StatelessWidget {
  const ShellTabReselectListener({
    super.key,
    required this.tabIndex,
    required this.onReselect,
    required this.child,
  });

  final int tabIndex;
  final VoidCallback onReselect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<MainScreenCubit, MainScreenState>(
      listenWhen: (MainScreenState previous, MainScreenState current) =>
          previous.tabReselectTick(tabIndex) !=
          current.tabReselectTick(tabIndex),
      listener: (BuildContext context, MainScreenState state) => onReselect(),
      child: child,
    );
  }
}
