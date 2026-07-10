import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/auth/domain/entities/registered_device.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/auth/presentation/cubit/manage_devices_cubit.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Manage Devices — lists the signed-in devices and lets the user sign out any
/// device, or all devices except this one. Reads are fetch-on-open; writes go
/// through Cloud Functions (ADR-008 Phase 3).
class ManageDevicesScreen extends StatelessWidget {
  const ManageDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userId = context.select<AuthBloc, String?>(
      (bloc) => switch (bloc.state) {
        AuthAuthenticated(:final user) => user.id,
        _ => null,
      },
    );

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.manageDevicesTitle)),
        body: const SizedBox.shrink(),
      );
    }

    return BlocProvider<ManageDevicesCubit>(
      create: (_) => getIt<ManageDevicesCubit>()..load(userId),
      child: _ManageDevicesView(userId: userId),
    );
  }
}

class _ManageDevicesView extends StatelessWidget {
  const _ManageDevicesView({required this.userId});

  final String userId;

  Future<void> _confirmSignOutOthers(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<ManageDevicesCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.manageDevicesSignOutOthers),
        content: Text(l10n.manageDevicesSignOutOthersConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.manageDevicesSignOutOthers),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await cubit.signOutOtherDevices(userId);
    if (!ok && context.mounted) {
      TilawaFeedback.showToast(
        context,
        message: l10n.manageDevicesSignOutFailed,
        variant: TilawaFeedbackVariant.error,
      );
    }
  }

  Future<void> _signOutDevice(BuildContext context, String deviceId) async {
    final l10n = context.l10n;
    final cubit = context.read<ManageDevicesCubit>();
    final ok = await cubit.signOutDevice(userId, deviceId);
    if (!ok && context.mounted) {
      TilawaFeedback.showToast(
        context,
        message: l10n.manageDevicesSignOutFailed,
        variant: TilawaFeedbackVariant.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageDevicesTitle)),
      body: BlocBuilder<ManageDevicesCubit, ManageDevicesState>(
        builder: (context, state) {
          return switch (state.status) {
            ManageDevicesStatus.initial ||
            ManageDevicesStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            ManageDevicesStatus.error => _ErrorView(
              message: l10n.manageDevicesError,
              onRetry: () => context.read<ManageDevicesCubit>().load(userId),
            ),
            ManageDevicesStatus.loaded => _DevicesList(
              state: state,
              onSignOutDevice: (id) => _signOutDevice(context, id),
            ),
          };
        },
      ),
      bottomNavigationBar: BlocBuilder<ManageDevicesCubit, ManageDevicesState>(
        buildWhen: (p, c) =>
            p.hasOtherActiveDevices != c.hasOtherActiveDevices ||
            p.signingOutOthers != c.signingOutOthers,
        builder: (context, state) {
          if (!state.hasOtherActiveDevices) {
            return const SizedBox.shrink();
          }
          return TilawaBottomActionArea(
            child: TilawaButton(
              text: l10n.manageDevicesSignOutOthers,
              variant: TilawaButtonVariant.dangerOutline,
              size: TilawaButtonSize.large,
              isFullWidth: true,
              isLoading: state.signingOutOthers,
              onPressed: state.signingOutOthers
                  ? null
                  : () => _confirmSignOutOthers(context),
            ),
          );
        },
      ),
    );
  }
}

class _DevicesList extends StatelessWidget {
  const _DevicesList({required this.state, required this.onSignOutDevice});

  final ManageDevicesState state;
  final ValueChanged<String> onSignOutDevice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final devices = state.devices;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceMedium,
        tokens.spaceLarge,
        tokens.spaceHuge,
      ),
      children: [
        Text(
          l10n.manageDevicesSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.spaceMedium),
        if (!state.hasOtherActiveDevices)
          Padding(
            padding: EdgeInsets.only(top: tokens.spaceMedium),
            child: Text(
              l10n.manageDevicesEmpty,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final device in devices) ...[
          _DeviceRow(
            device: device,
            isCurrent: state.isCurrent(device),
            busy: state.busyDeviceIds.contains(device.deviceId),
            onSignOut: () => onSignOutDevice(device.deviceId),
          ),
          SizedBox(height: tokens.spaceSmall),
        ],
      ],
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.device,
    required this.isCurrent,
    required this.busy,
    required this.onSignOut,
  });

  final RegisteredDevice device;
  final bool isCurrent;
  final bool busy;
  final VoidCallback onSignOut;

  IconData get _platformIcon => switch (device.platform) {
    'ios' => Icons.phone_iphone,
    'web' => Icons.public,
    _ => Icons.smartphone,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final l10n = context.l10n;
    final scheme = theme.colorScheme;

    final label = device.label?.isNotEmpty == true
        ? device.label!
        : device.platform;

    return TilawaCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(_platformIcon, color: scheme.primary),
          SizedBox(width: tokens.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                SizedBox(height: tokens.spaceExtraSmall),
                Text(
                  _statusLine(context, l10n),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: device.isRevoked
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: tokens.spaceSmall),
          _trailing(context, l10n),
        ],
      ),
    );
  }

  Widget _trailing(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    if (isCurrent) {
      return _Badge(
        text: l10n.manageDevicesThisDevice,
        color: theme.colorScheme.primary,
      );
    }
    if (device.isRevoked) {
      return _Badge(
        text: l10n.manageDevicesSignedOutBadge,
        color: theme.colorScheme.outline,
      );
    }
    if (busy) {
      return SizedBox.square(
        dimension: context.tokens.iconSizeMedium,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return TilawaButton(
      text: l10n.manageDevicesSignOutDevice,
      variant: TilawaButtonVariant.ghost,
      size: TilawaButtonSize.small,
      onPressed: onSignOut,
    );
  }

  String _statusLine(BuildContext context, AppLocalizations l10n) {
    if (device.isRevoked) {
      return l10n.manageDevicesSignedOutMessage;
    }
    final lastSeen = device.lastSeenAt;
    if (lastSeen == null) {
      return device.platform;
    }
    final when = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).add_jm().format(lastSeen.toLocal());
    return l10n.manageDevicesLastActive(when);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: tokens.spaceExtraSmall,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: tokens.opacityMedium),
        borderRadius: BorderRadius.circular(
          tokens.resolveRadius(family: TilawaRadiusFamily.chip),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: tokens.spaceMedium),
            TilawaButton(
              text: context.l10n.retry,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
