import '../entities/forced_update_host_platform.dart';

/// Resolves the current host for platform-specific min-build selection.
abstract class ForcedUpdateHostPlatformResolver {
  ForcedUpdateHostPlatform resolve();
}
