import 'package:get_it/get_it.dart';

import '../../../core/bootstrap/app_launch_config.dart';
import '../../../core/di/get_it_idempotent.dart';
import '../data/datasources/genui_fake_transport.dart';
import '../data/datasources/genui_gemini_transport.dart';
import '../data/datasources/genui_transport.dart';
import '../data/parser/genui_parser.dart';
import '../data/repositories/genui_repository_impl.dart';
import '../domain/repositories/genui_repository.dart';
import '../presentation/cubit/gen_ui_assistant_cubit.dart';
import '../presentation/render/genui_action_dispatcher.dart';
import '../presentation/render/genui_action_resolver.dart';
import '../presentation/render/genui_component_registry.dart';
import '../presentation/render/navigating_genui_intent_executor.dart';
import '../presentation/render/trusted_content_resolver.dart';

/// Wires the GenUI assistant into [GetIt] **only when the launch flag is on**.
///
/// When [AppLaunchConfig.genUiAssistantEnabled] is false the module registers
/// nothing — the feature has zero runtime footprint and is unreachable. When on,
/// it prefers the live Gemini transport if a `GEMINI_API_KEY` define is present,
/// and otherwise falls back to the deterministic fake transport (so QA builds
/// work without a key). Nothing here touches Firebase, the app name, or any
/// existing integration.
class GenUiAssistantModule {
  GenUiAssistantModule._();

  /// API key for the live transport. Supplied only at build time; absent by
  /// default, which keeps the live path dormant even when the flag is on.
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static void register(GetIt sl, {required AppLaunchConfig config}) {
    if (!config.genUiAssistantEnabled) return;

    sl.registerLazySingletonIfAbsent<GenUiTransport>(_buildTransport);
    sl.registerLazySingletonIfAbsent<GenUiParser>(() => const GenUiParser());
    sl.registerLazySingletonIfAbsent<GenUiRepository>(
      () => GenUiRepositoryImpl(
        transport: sl<GenUiTransport>(),
        parser: sl<GenUiParser>(),
      ),
    );

    sl.registerLazySingletonIfAbsent<TrustedContentResolver>(
      () => const DefaultTrustedContentResolver(),
    );
    sl.registerLazySingletonIfAbsent<GenUiActionResolver>(
      () => const GenUiActionResolver(),
    );
    sl.registerLazySingletonIfAbsent<GenUiComponentRegistry>(
      GenUiComponentRegistry.defaults,
    );
    sl.registerLazySingletonIfAbsent<GenUiActionDispatcher>(
      () => GenUiActionDispatcher(
        executor: const NavigatingGenUiIntentExecutor(),
        resolver: sl<GenUiActionResolver>(),
      ),
    );

    sl.registerFactoryIfAbsent<GenUiAssistantCubit>(
      () => GenUiAssistantCubit(repository: sl<GenUiRepository>()),
    );
  }

  static GenUiTransport _buildTransport() {
    if (_geminiApiKey.isNotEmpty) {
      return GenUiGeminiTransport(apiKey: _geminiApiKey);
    }
    return const GenUiFakeTransport();
  }
}
