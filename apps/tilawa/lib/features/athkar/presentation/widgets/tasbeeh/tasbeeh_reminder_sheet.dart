import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../domain/entities/tasbeeh_dhikr.dart';
import '../../cubit/tasbeeh_cubit.dart';

Future<void> showTasbeehReminderSheet({
  required BuildContext context,
  required TasbeehCubit cubit,
  required TasbeehDhikr dhikr,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return _TasbeehReminderSheet(cubit: cubit, dhikr: dhikr);
    },
  );
}

class _TasbeehReminderSheet extends StatefulWidget {
  const _TasbeehReminderSheet({required this.cubit, required this.dhikr});

  final TasbeehCubit cubit;
  final TasbeehDhikr dhikr;

  @override
  State<_TasbeehReminderSheet> createState() => _TasbeehReminderSheetState();
}

class _TasbeehReminderSheetState extends State<_TasbeehReminderSheet> {
  late bool _enabled;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _enabled = widget.dhikr.reminderEnabled;
    _time = TimeOfDay(
      hour: widget.dhikr.reminderHour ?? 9,
      minute: widget.dhikr.reminderMinute ?? 0,
    );
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _save() async {
    await widget.cubit.setReminderForActiveDhikr(
      enabled: _enabled,
      hour: _enabled ? _time.hour : null,
      minute: _enabled ? _time.minute : null,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLarge,
          tokens.spaceMedium,
          tokens.spaceLarge,
          tokens.spaceLarge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.tasbeehReminderSheetTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: tokens.spaceSmall),
            Text(
              widget.dhikr.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: tokens.spaceLarge),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.tasbeehReminderEnabledLabel),
              subtitle: Text(context.l10n.tasbeehReminderEnabledSubtitle),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            if (_enabled) ...[
              SizedBox(height: tokens.spaceSmall),
              TilawaButton(
                text: context.l10n.tasbeehReminderPickTime(
                  _time.format(context),
                ),
                leadingIcon: const Icon(Icons.schedule_rounded),
                variant: TilawaButtonVariant.outline,
                isFullWidth: true,
                onPressed: _pickTime,
              ),
            ],
            SizedBox(height: tokens.spaceLarge),
            TilawaButton(
              text: context.l10n.tasbeehSave,
              variant: TilawaButtonVariant.primary,
              isFullWidth: true,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
