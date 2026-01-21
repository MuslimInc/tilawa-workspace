import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tilawa_core/di/injection.dart';
import '../cubit/athkar_cubit.dart';
import '../cubit/athkar_state.dart';
import '../widgets/athkar_details_body.dart';

class AthkarDetailsScreen extends StatelessWidget {
  const AthkarDetailsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final int categoryId;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AthkarCubit>()..loadAthkar(categoryId),
      child: BlocBuilder<AthkarCubit, AthkarState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: Text(categoryName)),
            body: Builder(
              builder: (context) {
                if (state is AthkarLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is AthkarError) {
                  return Center(child: Text(state.message));
                } else if (state is AthkarItemsLoaded) {
                  return AthkarDetailsBody(
                    items: state.items,
                    currentCounts: state.currentCounts,
                    onPageChanged: (index) {},
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }
}
