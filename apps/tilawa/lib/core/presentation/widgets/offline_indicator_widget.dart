import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_bloc.dart';
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_state.dart';

class OfflineIndicatorWidget extends StatelessWidget {
  const OfflineIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InternetStatusBloc, InternetStatusState>(
      builder: (context, state) {
        if (state.status == InternetStatus.connected) {
          return const SizedBox.shrink();
        }

        return ColoredBox(
          color: Theme.of(context).colorScheme.error,
          child: SafeArea(
            bottom: false,
            left: false,
            right: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                context.l10n.noInternetConnection,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onError,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
