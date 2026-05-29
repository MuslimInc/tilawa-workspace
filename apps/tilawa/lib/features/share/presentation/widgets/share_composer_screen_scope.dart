import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';

import '../cubit/share_cubit.dart';

/// Composition root for share composer routes (`/share/screenshot`,
/// `/share/video-reel`).
class ShareComposerScreenScope extends StatelessWidget {
  const ShareComposerScreenScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ShareCubit>(),
      child: child,
    );
  }
}
