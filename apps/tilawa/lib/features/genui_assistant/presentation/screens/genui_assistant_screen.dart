import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/repositories/genui_repository.dart';
import '../cubit/gen_ui_assistant_cubit.dart';
import '../cubit/genui_assistant_state.dart';
import '../render/genui_action_dispatcher.dart';
import '../render/genui_component_registry.dart';
import '../render/genui_renderer.dart';
import '../render/genui_strings.dart';
import '../render/trusted_content_resolver.dart';

/// Isolated AI-generated surface. Reachable only when the launch flag is on and
/// only from its own entry point — never the home screen. Renders one of:
/// loading, a validated document, or a safe fallback.
class GenUiAssistantScreen extends StatelessWidget {
  const GenUiAssistantScreen({
    super.key,
    required this.cubit,
    required this.registry,
    required this.dispatcher,
    required this.content,
    required this.request,
  });

  final GenUiAssistantCubit cubit;
  final GenUiComponentRegistry registry;
  final GenUiActionDispatcher dispatcher;
  final TrustedContentResolver content;
  final GenUiSurfaceRequest request;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GenUiAssistantCubit>.value(
      value: cubit..load(request),
      child: Scaffold(
        appBar: AppBar(title: const Text('Smart Quran Plan')),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(Theme.of(context).tokens.spaceMedium),
            child: BlocBuilder<GenUiAssistantCubit, GenUiAssistantState>(
              builder: (context, state) => switch (state) {
                GenUiAssistantInitial() ||
                GenUiAssistantLoading() => const TilawaLoadingIndicator(),
                GenUiAssistantReady(:final document) => SingleChildScrollView(
                  child: GenUiRenderer(
                    document: document,
                    registry: registry,
                    dispatcher: dispatcher,
                    content: content,
                  ),
                ),
                GenUiAssistantFallback(:final failure) => TilawaErrorState(
                  icon: Icons.auto_awesome_outlined,
                  title: GenUiStrings.surfaceUnavailable,
                  subtitle: kDebugMode ? failure.message : null,
                  retryLabel: 'Try again',
                  onRetry: () =>
                      context.read<GenUiAssistantCubit>().load(request),
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}
