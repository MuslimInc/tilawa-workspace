/// AI-generated dynamic UI surface (Smart Quran Plan / MeMuslim Assistant).
///
/// Bounded server-driven UI: the model is a layout planner only. It emits a
/// versioned JSON document validated by [GenUiParser]; a closed component
/// whitelist ([GenUiComponentRegistry]) and a closed action allowlist
/// ([GenUiActionResolver]) map it onto ui_kit widgets and five typed intents.
/// Unknown components and actions fail closed. Religious content is resolved
/// from trusted sources via [TrustedContentResolver]; the model never authors
/// it. The whole feature is gated by `AppLaunchConfig.genUiAssistantEnabled`.
library;

export 'data/datasources/genui_fake_transport.dart';
export 'data/datasources/genui_gemini_transport.dart';
export 'data/datasources/genui_transport.dart';
export 'data/parser/genui_parser.dart';
export 'data/repositories/genui_repository_impl.dart';
export 'di/genui_assistant_module.dart';
export 'domain/entities/genui_document.dart';
export 'domain/entities/genui_intent.dart';
export 'domain/entities/genui_node.dart';
export 'domain/entities/genui_schema.dart';
export 'domain/failures/genui_failure.dart';
export 'domain/repositories/genui_repository.dart';
export 'presentation/cubit/gen_ui_assistant_cubit.dart';
export 'presentation/cubit/genui_assistant_state.dart';
export 'presentation/render/components/genui_components.dart';
export 'presentation/render/genui_action_dispatcher.dart';
export 'presentation/render/genui_action_resolver.dart';
export 'presentation/render/genui_component_registry.dart';
export 'presentation/render/genui_render_scope.dart';
export 'presentation/render/genui_renderer.dart';
export 'presentation/render/genui_strings.dart';
export 'presentation/render/logging_genui_intent_executor.dart';
export 'presentation/render/navigating_genui_intent_executor.dart';
export 'presentation/render/trusted_content_resolver.dart';
export 'presentation/screens/genui_assistant_screen.dart';
