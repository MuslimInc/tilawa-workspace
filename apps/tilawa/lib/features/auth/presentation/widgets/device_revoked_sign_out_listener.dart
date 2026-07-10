import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/auth/domain/services/device_revoked_notifier.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';

/// Signs this device out when a `device_revoked` FCM arrives (Manage Devices —
/// "Sign out this device" / "Sign out all other devices"). Definitive and
/// flag-agnostic: a user-intended remote sign-out always ends the session here.
///
/// Dispatches the standard [SignOutEvent] so the existing auth → router flow
/// routes to login. Sits above [MaterialApp], so it depends only on [AuthBloc]
/// (no lower-tree Localizations/feedback context).
class DeviceRevokedSignOutListener extends StatefulWidget {
  const DeviceRevokedSignOutListener({super.key, required this.child});

  final Widget child;

  @override
  State<DeviceRevokedSignOutListener> createState() =>
      _DeviceRevokedSignOutListenerState();
}

class _DeviceRevokedSignOutListenerState
    extends State<DeviceRevokedSignOutListener> {
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<DeviceRevokedNotifier>()) {
      _subscription = getIt<DeviceRevokedNotifier>().onDeviceRevoked.listen(
        (_) => _onDeviceRevoked(),
      );
    }
  }

  void _onDeviceRevoked() {
    if (!mounted) return;
    // Already signed out? Nothing to do.
    if (context.read<AuthBloc>().state is! AuthAuthenticated) {
      return;
    }
    context.read<AuthBloc>().add(const SignOutEvent());
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
