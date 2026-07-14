import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/forced_update/presentation/coordinators/forced_update_coordinator.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Developer settings entry that previews the blocking forced-update gate.
class ForcedUpdateDebugTile extends StatelessWidget {
  const ForcedUpdateDebugTile({
    super.key,
    this.isLast = false,
    this.debugMode = kDebugMode,
  });

  final bool isLast;
  final bool debugMode;

  @override
  Widget build(BuildContext context) {
    if (!debugMode) {
      return const SizedBox.shrink();
    }

    return TilawaSettingsTile(
      title: 'Forced update gate',
      subtitle: 'Preview the blocking update screen',
      showDivider: !isLast,
      onTap: () => getIt<ForcedUpdateCoordinator>().debugPreviewGate(),
    );
  }
}
