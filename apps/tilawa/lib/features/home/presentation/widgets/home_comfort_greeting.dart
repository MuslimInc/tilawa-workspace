import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_bloc.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_state.dart';

/// Simple greeting under the prayer card — name only, no coaching copy.
class HomeComfortGreeting extends StatelessWidget {
  const HomeComfortGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeDashboardBloc? bloc = _maybeBloc(context);
    if (bloc == null) {
      return Text(
        context.l10n.homeGreeting,
        style: _style(context),
      );
    }

    return BlocBuilder<HomeDashboardBloc, HomeDashboardState>(
      bloc: bloc,
      buildWhen: (previous, current) {
        final String? previousName = previous is HomeDashboardLoaded
            ? previous.dashboard.displayName
            : null;
        final String? currentName = current is HomeDashboardLoaded
            ? current.dashboard.displayName
            : null;
        return previousName != currentName ||
            previous.runtimeType != current.runtimeType;
      },
      builder: (context, state) {
        final String? name = state is HomeDashboardLoaded
            ? state.dashboard.displayName?.trim()
            : null;
        final bool hasName = name != null && name.isNotEmpty;
        final String greeting = hasName
            ? context.l10n.homeGreetingName(name)
            : context.l10n.homeGreeting;

        return Text(
          greeting,
          style: _style(context),
        );
      },
    );
  }

  TextStyle? _style(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );
  }

  HomeDashboardBloc? _maybeBloc(BuildContext context) {
    try {
      return context.read<HomeDashboardBloc>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}
