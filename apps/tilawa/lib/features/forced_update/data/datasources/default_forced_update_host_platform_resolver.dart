import 'package:flutter/foundation.dart';
import '../../domain/entities/forced_update_host_platform.dart';
import '../../domain/services/forced_update_host_platform_resolver.dart';

class DefaultForcedUpdateHostPlatformResolver
    implements ForcedUpdateHostPlatformResolver {
  const DefaultForcedUpdateHostPlatformResolver();

  @override
  ForcedUpdateHostPlatform resolve() {
    if (kIsWeb) {
      return ForcedUpdateHostPlatform.other;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => ForcedUpdateHostPlatform.android,
      TargetPlatform.iOS => ForcedUpdateHostPlatform.ios,
      _ => ForcedUpdateHostPlatform.other,
    };
  }
}
