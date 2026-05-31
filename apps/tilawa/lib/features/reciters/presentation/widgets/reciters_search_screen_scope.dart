import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';

import '../cubit/favorites_cubit.dart';
import '../cubit/reciters_search_cubit.dart';
import '../screens/reciters_search_screen.dart';

/// Composition root for [RecitersSearchScreen].
class RecitersSearchScreenScope extends StatelessWidget {
  const RecitersSearchScreenScope({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<RecitersSearchCubit>()),
        BlocProvider(create: (_) => getIt<FavoritesCubit>()..loadFavorites()),
      ],
      child: const RecitersSearchScreen(),
    );
  }
}
