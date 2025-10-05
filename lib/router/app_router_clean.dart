import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muzakri/core/di/injection_container.dart';
import 'package:muzakri/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:muzakri/features/reciters/presentation/screens/reciters_screen_clean.dart';
import 'package:muzakri/reciter_model.dart';
import 'package:muzakri/screens/playlists_screen.dart';
import 'package:muzakri/screens/reciter_details_screen.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => BlocProvider(
        create: (context) => sl<RecitersBloc>(),
        child: const RecitersScreenClean(),
      ),
    ),
    GoRoute(
      path: '/reciter/:reciterId',
      name: 'reciterDetails',
      builder: (context, state) {
        final reciter = state.extra as Reciter;
        return ReciterDetailsScreen(reciter: reciter);
      },
    ),
    GoRoute(
      path: '/playlists',
      name: 'playlists',
      builder: (context, state) => const PlaylistsScreen(),
    ),
  ],
);
