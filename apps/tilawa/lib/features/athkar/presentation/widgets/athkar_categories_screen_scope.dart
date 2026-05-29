import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';

import '../cubit/athkar_cubit.dart';
import '../screens/athkar_categories_screen.dart';

/// Composition root for [AthkarCategoriesScreen] (main tab and `/athkar` route).
class AthkarCategoriesScreenScope extends StatelessWidget {
  const AthkarCategoriesScreenScope({super.key, this.child});

  /// When set (e.g. in widget tests), replaces [AthkarCategoriesScreen].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AthkarCubit>()..loadCategories(),
      child: child ?? const AthkarCategoriesScreen(),
    );
  }
}
