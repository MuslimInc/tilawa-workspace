import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../cubit/athkar_cubit.dart';
import '../cubit/athkar_state.dart';
import '../widgets/athkar_details_body.dart';

class AthkarDetailsScreen extends StatefulWidget {
  const AthkarDetailsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.source = 'manual',
  });

  final int categoryId;
  final String categoryName;
  final String source;

  @override
  State<AthkarDetailsScreen> createState() => _AthkarDetailsScreenState();
}

class _AthkarDetailsScreenState extends State<AthkarDetailsScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    getIt<AnalyticsService>().logAthkarReadStart(
      widget.categoryId,
      widget.categoryName,
      source: widget.source,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AthkarCubit>()..loadAthkar(widget.categoryId),
      child: BlocBuilder<AthkarCubit, AthkarState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              actions: [
                if (state is AthkarItemsLoaded) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${state.items.length}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ],
              title: Text(widget.categoryName),
            ),
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
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
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
