import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../core/extensions.dart';
import '../bloc/reciter_details_bloc.dart';
import '../bloc/reciter_download_bloc.dart';
import '../cubit/reciter_details_loader_cubit.dart';
import '../cubit/reciter_details_loader_state.dart';
import 'reciter_details_screen.dart';

class ReciterDetailsLoader extends StatelessWidget {
  const ReciterDetailsLoader({super.key, required this.reciterId});

  final String reciterId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReciterDetailsLoaderCubit>()..loadReciter(reciterId),
      child: TilawaShellChildScaffold(
        body: BlocBuilder<ReciterDetailsLoaderCubit, ReciterDetailsLoaderState>(
          builder: (context, state) {
            if (state is ReciterDetailsLoaderLoading) {
              return const TilawaLoadingIndicator();
            }

            if (state is ReciterDetailsLoaderFailure) {
              return TilawaErrorState(
                icon: Icons.error_outline,
                title: state.message,
                retryLabel: context.l10n.retry,
                onRetry: () {
                  context.read<ReciterDetailsLoaderCubit>().loadReciter(
                    reciterId,
                  );
                },
                iconColor: Theme.of(context).colorScheme.error,
              );
            }

            if (state is ReciterDetailsLoaderSuccess) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (context) => getIt<ReciterDetailsBloc>(),
                  ),
                  BlocProvider(
                    create: (context) => getIt<ReciterDownloadBloc>(),
                  ),
                ],
                child: ReciterDetailsScreen(reciter: state.reciter),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
