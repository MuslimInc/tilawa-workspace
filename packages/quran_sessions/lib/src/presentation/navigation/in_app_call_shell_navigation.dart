import 'package:flutter/material.dart';

import '../../domain/entities/session_call_provider_kind.dart';
import '../../domain/entities/session_call_type.dart';
import '../screens/in_app_call_shell_screen.dart';
import '../../boundaries/call/session_call_control_gateway.dart';

typedef SessionCallControlGatewayFactory =
    SessionCallControlGateway Function(String sessionId);

/// Pushes [InAppCallShellScreen] after a successful in-app join.
Future<void> pushInAppCallShell(
  BuildContext context, {
  required String sessionId,
  required SessionCallType callType,
  required SessionCallProviderKind callProviderKind,
  String? participantName,
  String? participantSubtitle,
  InAppCallSurfaceBuilder? buildCallSurface,
  SessionCallControlGatewayFactory? createCallControlGateway,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'in_app_call_shell'),
      builder: (routeContext) => InAppCallShellScreen(
        sessionId: sessionId,
        callType: callType,
        callProviderKind: callProviderKind,
        participantName: participantName,
        participantSubtitle: participantSubtitle,
        callSurface: buildCallSurface?.call(
          routeContext,
          sessionId: sessionId,
          callType: callType,
          callProviderKind: callProviderKind,
        ),
        callControlGateway: createCallControlGateway?.call(sessionId),
      ),
    ),
  );
}
