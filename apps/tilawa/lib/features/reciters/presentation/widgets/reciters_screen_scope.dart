import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';

import '../../domain/usecases/get_reciters_use_case.dart';
import '../bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import '../bloc/reciters_bloc.dart';
import '../screens/reciters_screen.dart';

/// Composition root for [RecitersScreen] (main tab 0).
class RecitersScreenScope extends StatelessWidget {
  const RecitersScreenScope({super.key});

  static RecitersBloc _createRecitersBloc() {
    final getReciters = getIt<GetRecitersUseCase>();
    return RecitersBloc(
      getReciters,
      initialReciters: getReciters.takeCachedSuccessForStartup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => _createRecitersBloc()),
        BlocProvider(create: (_) => getIt<AlphabetScrollbarBloc>()),
      ],
      child: const RecitersScreen(),
    );
  }
}
