import 'call_provider.dart';
import 'call_room.dart';
import 'call_token_provider.dart';

/// Placeholder for V2 Agora voice/video integration.
///
/// ⚠️  DO NOT add `agora_rtc_engine` as a dependency until V2 is scoped.
/// This class intentionally throws [UnimplementedError] so the compiler
/// flags any premature wiring.
///
/// When implementing:
/// 1. Add `agora_rtc_engine` to pubspec.yaml.
/// 2. Replace the [UnimplementedError] bodies with real Agora SDK calls.
/// 3. Use [CallTokenProvider] to fetch the RTC token before joining.
class AgoraCallProvider implements CallProvider {
  const AgoraCallProvider({required this.tokenProvider, required this.appId});

  final CallTokenProvider tokenProvider;
  final String appId;

  @override
  Future<CallRoom> joinSession(String sessionId) => throw UnimplementedError(
    'AgoraCallProvider.joinSession — V2 not yet implemented',
  );

  @override
  Future<void> leaveSession(String sessionId) => throw UnimplementedError(
    'AgoraCallProvider.leaveSession — V2 not yet implemented',
  );

  @override
  Future<void> endSession(String sessionId) => throw UnimplementedError(
    'AgoraCallProvider.endSession — V2 not yet implemented',
  );
}
