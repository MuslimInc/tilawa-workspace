import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../data/khatma_reminder_notification_service.dart';
import '../../domain/constants/khatma_reminder_constants.dart';

KhatmaReminderNotificationService? _khatmaReminderService() {
  if (!getIt.isRegistered<KhatmaReminderNotificationService>()) {
    return null;
  }
  return getIt<KhatmaReminderNotificationService>();
}

Future<void> promptKhatmaDailyReminder(BuildContext context) async {
  final bool? accepted = await showTilawaConfirmDialog(
    context: context,
    title: context.l10n.khatmaReminderOptInTitle,
    message: context.l10n.khatmaReminderOptInMessage,
    confirmLabel: context.l10n.khatmaReminderOptInYes,
    cancelLabel: context.l10n.khatmaReminderOptInNo,
    compactCloseButton: true,
    compactActions: true,
  );
  if (!context.mounted) return;

  final service = _khatmaReminderService();
  if (service != null) {
    await service.preferences.setDailyPromptShown(shown: true);
  }

  if (accepted != true) return;

  if (service != null) {
    await service.enableDailyReminder();
  }
  if (!context.mounted) return;

  await showTilawaConfirmDialog(
    context: context,
    title: context.l10n.khatmaReminderSetTitle,
    message: context.l10n.khatmaReminderSetMessage,
    confirmLabel: context.l10n.khatmaReminderContinue,
    cancelLabel: context.l10n.cancel,
    compactCloseButton: true,
    compactActions: true,
  );
}

Future<void> promptKhatmaSurahReminders(BuildContext context) async {
  final service = _khatmaReminderService();
  final l10n = context.l10n;

  final bool? baqarah = await showTilawaConfirmDialog(
    context: context,
    title: l10n.khatmaBaqarahReminderTitle,
    message: l10n.khatmaBaqarahReminderPromptMessage,
    confirmLabel: l10n.khatmaReminderOptInYes,
    cancelLabel: l10n.khatmaReminderOptInNo,
    compactCloseButton: true,
    compactActions: true,
  );
  if (!context.mounted) return;
  if (baqarah == true && service != null) {
    await service.enableBaqarahReminder();
  }

  if (!context.mounted) return;
  final bool? kahf = await showTilawaConfirmDialog(
    context: context,
    title: l10n.khatmaKahfReminderTitle,
    message: l10n.khatmaKahfReminderPromptMessage,
    confirmLabel: l10n.khatmaReminderOptInYes,
    cancelLabel: l10n.khatmaReminderOptInNo,
    compactCloseButton: true,
    compactActions: true,
  );
  if (!context.mounted) return;
  if (kahf == true && service != null) {
    await service.enableKahfReminder();
  }

  if (service != null) {
    await service.preferences.setSurahPromptShown(shown: true);
  }
}

Future<void> showKhatmaReminderSettingsSheet(BuildContext context) {
  return showTilawaModalBottomSheet<void>(
    context: context,
    // Sheet body applies [floatingBottomPadding] itself so Android devices
    // that report 0 MediaQuery bottom inset still clear the gesture bar.
    useSafeArea: false,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: TilawaBottomSheetScaffold.modalShape(context),
    builder: (_) => const _KhatmaReminderSettingsSheet(),
  );
}

class _KhatmaReminderSettingsSheet extends StatefulWidget {
  const _KhatmaReminderSettingsSheet();

  @override
  State<_KhatmaReminderSettingsSheet> createState() =>
      _KhatmaReminderSettingsSheetState();
}

class _KhatmaReminderSettingsSheetState
    extends State<_KhatmaReminderSettingsSheet> {
  bool _loading = true;
  bool _dailyEnabled = false;
  bool _baqarahEnabled = false;
  bool _kahfEnabled = false;
  TimeOfDay _dailyTime = const TimeOfDay(
    hour: KhatmaReminderConstants.defaultHour,
    minute: KhatmaReminderConstants.defaultMinute,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_loadPreferences());
  }

  Future<void> _loadPreferences() async {
    final service = _khatmaReminderService();
    if (service == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final prefs = service.preferences;
    final results = await Future.wait([
      prefs.isDailyEnabled(),
      prefs.isBaqarahEnabled(),
      prefs.isKahfEnabled(),
      prefs.dailyHour(),
      prefs.dailyMinute(),
    ]);
    if (!mounted) return;
    setState(() {
      _dailyEnabled = results[0] as bool;
      _baqarahEnabled = results[1] as bool;
      _kahfEnabled = results[2] as bool;
      _dailyTime = TimeOfDay(
        hour: results[3] as int,
        minute: results[4] as int,
      );
      _loading = false;
    });
  }

  Future<void> _pickDailyTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dailyTime,
    );
    if (picked != null) {
      setState(() => _dailyTime = picked);
      final service = _khatmaReminderService();
      if (service != null && _dailyEnabled) {
        await service.scheduleDailyReminder(
          hour: picked.hour,
          minute: picked.minute,
        );
      }
    }
  }

  Future<void> _setDailyEnabled(bool enabled) async {
    setState(() => _dailyEnabled = enabled);
    final service = _khatmaReminderService();
    if (service == null) return;
    if (enabled) {
      await service.enableDailyReminder(
        hour: _dailyTime.hour,
        minute: _dailyTime.minute,
      );
    } else {
      await service.disableDailyReminder();
    }
  }

  Future<void> _setBaqarahEnabled(bool enabled) async {
    setState(() => _baqarahEnabled = enabled);
    final service = _khatmaReminderService();
    if (service == null) return;
    if (enabled) {
      await service.enableBaqarahReminder();
    } else {
      await service.disableBaqarahReminder();
    }
  }

  Future<void> _setKahfEnabled(bool enabled) async {
    setState(() => _kahfEnabled = enabled);
    final service = _khatmaReminderService();
    if (service == null) return;
    if (enabled) {
      await service.enableKahfReminder();
    } else {
      await service.disableKahfReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final EdgeInsets bodyPadding =
        TilawaBottomSheetScaffold.resolvedBodyPadding(context);
    final EdgeInsets paddedBody = bodyPadding.copyWith(
      bottom: bodyPadding.bottom + context.floatingBottomPadding,
    );

    return TilawaBottomSheetScaffold(
      topBar: TilawaBottomSheetTitleRow(
        title: context.l10n.khatmaReminderSettingsTitle,
        trailingClose: true,
      ),
      children: [
        if (_loading)
          Padding(
            padding: paddedBody,
            child: const Center(child: TilawaLoadingIndicator()),
          )
        else
          Padding(
            padding: paddedBody,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: tokens.spaceMedium,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.khatmaReminderSettingsTitle),
                  subtitle: Text(context.l10n.khatmaReminderSettingsSubtitle),
                  value: _dailyEnabled,
                  onChanged: _setDailyEnabled,
                ),
                if (_dailyEnabled)
                  TilawaButton(
                    text: MaterialLocalizations.of(context).formatTimeOfDay(
                      _dailyTime,
                    ),
                    leadingIcon: const Icon(Icons.schedule_rounded),
                    variant: TilawaButtonVariant.outline,
                    isFullWidth: true,
                    onPressed: _pickDailyTime,
                  ),
                Text(
                  context.l10n.khatmaSurahRemindersTitle,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  context.l10n.khatmaSurahRemindersSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.khatmaBaqarahReminderTitle),
                  subtitle: Text(context.l10n.khatmaBaqarahReminderBody),
                  value: _baqarahEnabled,
                  onChanged: _setBaqarahEnabled,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.khatmaKahfReminderTitle),
                  subtitle: Text(context.l10n.khatmaKahfReminderBody),
                  value: _kahfEnabled,
                  onChanged: _setKahfEnabled,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
