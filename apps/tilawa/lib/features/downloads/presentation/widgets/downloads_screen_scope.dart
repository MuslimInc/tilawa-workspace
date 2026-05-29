import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';

import '../bloc/downloads_bloc.dart';
import '../screens/downloads_screen.dart';

/// Composition root for [DownloadsScreen]; bloc lives only while `/downloads`
/// is mounted.
class DownloadsScreenScope extends StatelessWidget {
  const DownloadsScreenScope({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DownloadsBloc>(),
      child: const DownloadsScreen(),
    );
  }
}
