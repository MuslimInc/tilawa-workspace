import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/notifications/debug/notification_debug_action_catalog.dart';
import 'package:tilawa/features/notifications/debug/notification_debug_constants.dart';
import 'package:tilawa/features/notifications/debug/notification_debug_dedup_snapshot.dart';
import 'package:tilawa/features/notifications/debug/notification_debug_lab_service.dart';
import 'package:tilawa/features/notifications/debug/notification_debug_log_store.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Developer-only screen to exercise notification routing and dedup paths.
class NotificationDebugLabScreen extends StatefulWidget {
  const NotificationDebugLabScreen({super.key});

  @override
  State<NotificationDebugLabScreen> createState() =>
      _NotificationDebugLabScreenState();
}

class _NotificationDebugLabScreenState
    extends State<NotificationDebugLabScreen> {
  late final NotificationDebugLabService _service;
  late final NotificationDebugLogStore _logStore;
  NotificationDebugDedupSnapshot? _snapshot;
  bool _loadingSnapshot = false;

  @override
  void initState() {
    super.initState();
    _service = getIt<NotificationDebugLabService>();
    _logStore = getIt<NotificationDebugLogStore>();
    _logStore.addListener(_onLogsChanged);
    _refreshSnapshot();
  }

  @override
  void dispose() {
    _logStore.removeListener(_onLogsChanged);
    super.dispose();
  }

  void _onLogsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshSnapshot() async {
    setState(() => _loadingSnapshot = true);
    final NotificationDebugDedupSnapshot snapshot = await _service.readSnapshot(
      previewNotificationId: NotificationDebugConstants.morningAthkar,
      previewPayload: NotificationDebugConstants.morningAthkarPayload(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = snapshot;
      _loadingSnapshot = false;
    });
  }

  Future<void> _runAction(NotificationDebugActionSpec spec) async {
    if (spec.scheduleDelay != null) {
      final AppLocalizations l10n = AppLocalizations.of(context);
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(l10n.notificationDebugLabTitle),
          content: Text(l10n.notificationDebugConfirmSchedule),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
    }
    await _service.runAction(spec);
    await _refreshSnapshot();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      appBar: TilawaAppBar(title: l10n.notificationDebugLabTitle),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(tokens.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ActionSection(
              key: const ValueKey('notification_debug_local_section'),
              title: l10n.notificationDebugSectionLocal,
              actions: NotificationDebugActionCatalog.localNotificationActions(
                l10n,
              ),
              onRun: _runAction,
            ),
            SizedBox(height: tokens.spaceExtraLarge),
            _ActionSection(
              key: const ValueKey('notification_debug_launch_section'),
              title: l10n.notificationDebugSectionLaunch,
              actions: NotificationDebugActionCatalog.launchSimulationActions(
                l10n,
              ),
              onRun: _runAction,
            ),
            SizedBox(height: tokens.spaceExtraLarge),
            TilawaSectionHeader(
              key: const ValueKey('notification_debug_dedup_section'),
              title: l10n.notificationDebugSectionDedup,
            ),
            SizedBox(height: tokens.spaceSmall),
            if (_loadingSnapshot)
              const Center(child: CircularProgressIndicator())
            else if (_snapshot != null)
              _DedupInspector(snapshot: _snapshot!, l10n: l10n),
            SizedBox(height: tokens.spaceSmall),
            Wrap(
              spacing: tokens.spaceSmall,
              runSpacing: tokens.spaceSmall,
              children: <Widget>[
                OutlinedButton(
                  onPressed: _refreshSnapshot,
                  child: Text(l10n.notificationDebugRefreshState),
                ),
                OutlinedButton(
                  key: const ValueKey('notification_debug_clear_dedup'),
                  onPressed: () async {
                    await _service.clearDedupState();
                    await _refreshSnapshot();
                  },
                  child: Text(l10n.notificationDebugClearDedup),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await _service.clearAthkarDedupState();
                    await _refreshSnapshot();
                  },
                  child: Text(l10n.notificationDebugClearAthkarDedup),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await _service.clearAllDebugState();
                    await _refreshSnapshot();
                  },
                  child: Text(l10n.notificationDebugClearAll),
                ),
              ],
            ),
            SizedBox(height: tokens.spaceExtraLarge),
            TilawaSectionHeader(title: l10n.notificationDebugSectionChecklist),
            SizedBox(height: tokens.spaceSmall),
            _ChecklistSection(l10n: l10n),
            SizedBox(height: tokens.spaceExtraLarge),
            TilawaSectionHeader(
              key: const ValueKey('notification_debug_logs_section'),
              title: l10n.notificationDebugSectionLogs,
              trailing: TextButton(
                onPressed: _logStore.clear,
                child: Text(l10n.notificationDebugClearLogs),
              ),
            ),
            SizedBox(height: tokens.spaceSmall),
            if (_logStore.entries.isEmpty)
              Text(
                l10n.notificationDebugLogsEmpty,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
              ..._logStore.entries
                  .take(20)
                  .map(
                    (NotificationDebugLogEntry entry) => Padding(
                      padding: EdgeInsets.only(bottom: tokens.spaceExtraSmall),
                      child: Text(
                        '${entry.timestamp.toIso8601String()} · '
                        '${entry.event}'
                        '${entry.detail == null ? '' : ' · ${entry.detail}'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'Courier',
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    super.key,
    required this.title,
    required this.actions,
    required this.onRun,
  });

  final String title;
  final List<NotificationDebugActionSpec> actions;
  final Future<void> Function(NotificationDebugActionSpec spec) onRun;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TilawaSectionHeader(title: title),
        SizedBox(height: tokens.spaceSmall),
        ...actions.map((NotificationDebugActionSpec spec) {
          return Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceSmall),
            child: TilawaCard(
              onTap: () => onRun(spec),
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      spec.key,
                      style: theme.textTheme.titleSmall,
                    ),
                    SizedBox(height: tokens.spaceExtraSmall),
                    _MetaRow(
                      label: l10n.notificationDebugActionId,
                      value: spec.notificationId?.toString() ?? '(null)',
                    ),
                    _MetaRow(
                      label: l10n.notificationDebugActionPayload,
                      value: spec.payload ?? '(null)',
                    ),
                    _MetaRow(
                      label: l10n.notificationDebugActionRoute,
                      value: spec.expectedRoute,
                    ),
                    _MetaRow(
                      label: l10n.notificationDebugActionBehavior,
                      value: spec.expectedBehavior,
                    ),
                    _MetaRow(
                      label: l10n.notificationDebugActionMechanism,
                      value: NotificationDebugActionCatalog.mechanismLabel(
                        l10n,
                        spec.mechanism,
                      ),
                    ),
                    SizedBox(height: tokens.spaceExtraSmall),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Chip(
                        label: Text(
                          NotificationDebugActionCatalog.mechanismLabel(
                            l10n,
                            spec.mechanism,
                          ),
                          style: theme.textTheme.labelSmall,
                        ),
                        backgroundColor: scheme.surfaceContainerHighest,
                        side: BorderSide(
                          color: scheme.outlineVariant,
                          width: tokens.borderWidthThin,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceTiny),
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DedupInspector extends StatelessWidget {
  const _DedupInspector({required this.snapshot, required this.l10n});

  final NotificationDebugDedupSnapshot snapshot;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    return TilawaCard(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _MetaRow(
              label: l10n.notificationDebugFieldCurrentPid,
              value: '${snapshot.currentPid}',
            ),
            _MetaRow(
              label: l10n.notificationDebugFieldStoredPid,
              value: '${snapshot.storedPid ?? '(null)'}',
            ),
            _MetaRow(
              label: l10n.notificationDebugFieldStoredId,
              value: '${snapshot.storedNotificationId ?? '(null)'}',
            ),
            _MetaRow(
              label: l10n.notificationDebugFieldStoredSig,
              value: snapshot.storedPayloadSignature ?? '(null)',
            ),
            _MetaRow(
              label: l10n.notificationDebugFieldLastProcessedId,
              value: '${snapshot.lastProcessedNotificationId ?? '(null)'}',
            ),
            _MetaRow(
              label: l10n.notificationDebugFieldPendingRoute,
              value: snapshot.pendingColdStartLocation ?? '(null)',
            ),
            _MetaRow(
              label: l10n.notificationDebugFieldPendingExtra,
              value: '${snapshot.pendingColdStartExtra ?? '(null)'}',
            ),
            _MetaRow(
              label: l10n.notificationDebugFieldAthkarPayload,
              value: snapshot.athkarLastHandledPayload ?? '(null)',
            ),
            _MetaRow(
              label: l10n.notificationDebugFieldAthkarTimestamp,
              value: '${snapshot.athkarLastHandledTimestampMs ?? '(null)'}',
            ),
            _MetaRow(
              label: l10n.notificationDebugFieldPreviewSig,
              value: snapshot.incomingSignaturePreview ?? '(null)',
            ),
            _MetaRow(
              label: l10n.notificationDebugFieldProcessedPreview,
              value: '${snapshot.isProcessedPreview ?? '(null)'}',
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistSection extends StatelessWidget {
  const _ChecklistSection({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;

    final List<(String title, List<String> items)> sections =
        <(String, List<String>)>[
          (
            l10n.notificationDebugChecklistAthkarTitle,
            <String>[
              l10n.notificationDebugChecklistAthkarTap,
              l10n.notificationDebugChecklistAthkarRestart,
            ],
          ),
          (
            l10n.notificationDebugChecklistPrayerTitle,
            <String>[
              l10n.notificationDebugChecklistPrayerTap,
              l10n.notificationDebugChecklistPrayerRestart,
            ],
          ),
          (
            l10n.notificationDebugChecklistInvalidTitle,
            <String>[l10n.notificationDebugChecklistInvalidBody],
          ),
          (
            l10n.notificationDebugChecklistSettingsTitle,
            <String>[l10n.notificationDebugChecklistSettingsBody],
          ),
          (
            l10n.notificationDebugChecklistSameSigTitle,
            <String>[
              l10n.notificationDebugChecklistSameSigTap,
              l10n.notificationDebugChecklistSameSigRestart,
            ],
          ),
          (
            l10n.notificationDebugChecklistDiffPayloadTitle,
            <String>[l10n.notificationDebugChecklistDiffPayloadBody],
          ),
          (
            l10n.notificationDebugChecklistDiffIdTitle,
            <String>[l10n.notificationDebugChecklistDiffIdBody],
          ),
          (
            l10n.notificationDebugChecklistKillTitle,
            <String>[l10n.notificationDebugChecklistKillSteps],
          ),
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections.map(((String title, List<String> items) section) {
        return Padding(
          padding: EdgeInsets.only(bottom: tokens.spaceMedium),
          child: TilawaCard(
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(section.$1, style: theme.textTheme.titleSmall),
                  SizedBox(height: tokens.spaceExtraSmall),
                  ...section.$2.map(
                    (String item) => Padding(
                      padding: EdgeInsets.only(bottom: tokens.spaceTiny),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            FluentIcons.checkbox_unchecked_24_regular,
                            size: tokens.iconSizeSmall,
                          ),
                          SizedBox(width: tokens.spaceExtraSmall),
                          Expanded(
                            child: Text(item, style: theme.textTheme.bodySmall),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
