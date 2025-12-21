import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/athkar_item.dart';
import '../cubit/athkar_cubit.dart';
import '../cubit/athkar_state.dart';
import '../widgets/athkar_item_widget.dart';

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
      child: Scaffold(
        appBar: AppBar(title: Text(categoryName)),
        body: BlocBuilder<AthkarCubit, AthkarState>(
          builder: (context, state) {
            if (state is AthkarLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AthkarError) {
              return Center(child: Text(state.message));
            } else if (state is AthkarItemsLoaded) {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final AthkarItem item = state.items[index];
                  final int currentCount = state.currentCounts[item.id] ?? 0;
                  return AthkarItemWidget(
                    item: item,
                    currentCount: currentCount,
                    onTap: () {
                      context.read<AthkarCubit>().decrementCount(item.id);
                    },
                    onReset: () {
                      context.read<AthkarCubit>().resetCount(item.id);
                    },
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
