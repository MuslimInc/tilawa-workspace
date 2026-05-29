import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';

import '../bloc/qibla_bloc.dart';
import '../screens/qibla_screen.dart';

/// Composition root for [QiblaScreen]; bloc lives only while `/qibla` is mounted.
class QiblaScreenScope extends StatelessWidget {
  const QiblaScreenScope({super.key, this.child});

  /// When set (e.g. in widget tests), replaces [QiblaScreen].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<QiblaBloc>(),
      child: child ?? const QiblaScreen(),
    );
  }
}
