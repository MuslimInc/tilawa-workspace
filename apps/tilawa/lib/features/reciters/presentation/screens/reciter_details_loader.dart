import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:tilawa_core/di/injection.dart';
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
      child: Scaffold(
        body: BlocBuilder<ReciterDetailsLoaderCubit, ReciterDetailsLoaderState>(
          builder: (context, state) {
            if (state is ReciterDetailsLoaderLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ReciterDetailsLoaderFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                    SizedBox(height: 16.h),
                    Text(state.message),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ReciterDetailsLoaderCubit>().loadReciter(
                          reciterId,
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
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
