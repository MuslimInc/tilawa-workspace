import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'package:tilawa/core/extensions.dart';
import '../../../../shared/models/position_data.dart';
import '../bloc/audio_player_bloc.dart';
import '../quran_player_semantics_ids.dart';

class SleepTimerDialog extends StatelessWidget {
  const SleepTimerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Semantics(
      identifier: QuranPlayerSemanticsIds.sleepTimerDialog,
      container: true,
      child: Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
      ),
      backgroundColor: colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceExtraLarge),
        child: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.recitationDuration,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (state.isSleepTimerActive)
                      TilawaStatusChip(
                        icon: Icons.timer_rounded,
                        label: context.l10n.sleepTimerActive,
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                      ),
                  ],
                ),
                SizedBox(height: tokens.spaceExtraLarge),

                // Options Grid
                Wrap(
                  spacing: tokens.spaceMedium,
                  runSpacing: tokens.spaceMedium,
                  alignment: WrapAlignment.center,
                  children: [
                    Semantics(
                      identifier: QuranPlayerSemanticsIds.sleepTimer15,
                      button: true,
                      child: _buildTimerChip(
                        context,
                        context.l10n.minutes15,
                        const Duration(minutes: 15),
                        state,
                      ),
                    ),
                    Semantics(
                      identifier: QuranPlayerSemanticsIds.sleepTimer30,
                      button: true,
                      child: _buildTimerChip(
                        context,
                        context.l10n.minutes30,
                        const Duration(minutes: 30),
                        state,
                      ),
                    ),
                    Semantics(
                      identifier: QuranPlayerSemanticsIds.sleepTimer60,
                      button: true,
                      child: _buildTimerChip(
                        context,
                        context.l10n.minutes60,
                        const Duration(minutes: 60),
                        state,
                      ),
                    ),
                    Semantics(
                      identifier: QuranPlayerSemanticsIds.sleepTimerEndOfTrack,
                      button: true,
                      child: _buildEndTrackChip(context, state),
                    ),
                    Semantics(
                      identifier: QuranPlayerSemanticsIds.sleepTimerCustom,
                      button: true,
                      child: _buildCustomChip(context, state),
                    ),
                  ],
                ),

                SizedBox(height: tokens.spaceExtraLarge),

                // Cancel Button
                if (state.isSleepTimerActive)
                  Semantics(
                    identifier: QuranPlayerSemanticsIds.sleepTimerCancel,
                    button: true,
                    child: TilawaButton(
                      text: context.l10n.cancelTimer,
                      variant: TilawaButtonVariant.danger,
                      isFullWidth: true,
                      leadingIcon: const Icon(Icons.timer_off_outlined),
                      onPressed: () {
                        context.read<AudioPlayerBloc>().add(
                          const AudioPlayerEvent.cancelSleepTimer(),
                        );
                        context.pop();
                      },
                    ),
                  )
                else
                  Semantics(
                    identifier: QuranPlayerSemanticsIds.sleepTimerClose,
                    button: true,
                    child: TilawaButton(
                      text: context.l10n.cancel,
                      variant: TilawaButtonVariant.ghost,
                      isFullWidth: true,
                      onPressed: () => context.pop(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }

  Widget _buildTimerChip(
    BuildContext context,
    String label,
    Duration duration,
    AudioPlayerState state,
  ) {
    final isActive =
        state.lastSleepTimerType == SleepTimerType.preset &&
        state.lastSleepTimerDuration == duration;
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return ActionChip(
      label: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: isActive
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant,
          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceSmall,
      ),
      backgroundColor: isActive
          ? colorScheme.primary
          : colorScheme.surfaceContainerLow,
      side: BorderSide(
        color: isActive
            ? colorScheme.primary
            : colorScheme.outlineVariant.withValues(
                alpha: tokens.opacityMedium,
              ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      onPressed: () {
        context.read<AudioPlayerBloc>().add(
          AudioPlayerEvent.setSleepTimer(duration),
        );
        context.pop();
      },
    );
  }

  Widget _buildEndTrackChip(BuildContext context, AudioPlayerState state) {
    final Duration? remaining = _calculateRemaining(state);
    final bool canUse = remaining != null && remaining.inSeconds > 0;
    final bool isActive =
        state.isSleepTimerActive &&
        state.lastSleepTimerType == SleepTimerType.endOfTrack;
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return ActionChip(
      label: Text(
        context.l10n.endOfTrack,
        style: theme.textTheme.labelLarge?.copyWith(
          color: isActive
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant,
          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceSmall,
      ),
      backgroundColor: isActive
          ? colorScheme.primary
          : colorScheme.surfaceContainerLow,
      side: BorderSide(
        color: isActive
            ? colorScheme.primary
            : colorScheme.outlineVariant.withValues(
                alpha: tokens.opacityMedium,
              ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      avatar: canUse
          ? Icon(
              Icons.skip_next,
              size: tokens.iconSizeSmall,
              color: isActive
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            )
          : null,
      onPressed: canUse
          ? () {
              context.read<AudioPlayerBloc>().add(
                AudioPlayerEvent.setSleepTimer(
                  remaining,
                  type: SleepTimerType.endOfTrack,
                ),
              );
              context.pop();
            }
          : null, // Disable if unknown duration
    );
  }

  Widget _buildCustomChip(BuildContext context, AudioPlayerState state) {
    final bool isActive =
        state.isSleepTimerActive &&
        state.lastSleepTimerType == SleepTimerType.custom;
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return ActionChip(
      label: Text(
        context.l10n.custom,
        style: theme.textTheme.labelLarge?.copyWith(
          color: isActive
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant,
          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceSmall,
      ),
      backgroundColor: isActive
          ? colorScheme.primary
          : colorScheme.surfaceContainerLow,
      side: BorderSide(
        color: isActive
            ? colorScheme.primary
            : colorScheme.outlineVariant.withValues(
                alpha: tokens.opacityMedium,
              ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      avatar: Icon(
        Icons.edit_outlined,
        size: tokens.iconSizeSmall,
        color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
      ),
      onPressed: () => _pickCustomDuration(context),
    );
  }

  Duration? _calculateRemaining(AudioPlayerState state) {
    final PositionData? pos = state.positionData;
    if (pos == null || pos.duration == Duration.zero) {
      return null;
    }
    final Duration remaining = pos.duration - pos.position;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> _pickCustomDuration(BuildContext context) async {
    var tempDuration = const Duration(minutes: 15);
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    final Duration? picked = await showTilawaModalBottomSheet<Duration>(
      context: context,
      backgroundColor: Colors.transparent, // For custom container shape
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: 350,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(tokens.radiusExtraLarge),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                const TilawaSheetHandle(),
                // Actions
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TilawaButton(
                        text: context.l10n.cancel,
                        variant: TilawaButtonVariant.ghost,
                        size: TilawaButtonSize.small,
                        onPressed: () => context.pop(),
                      ),
                      Text(
                        context.l10n.setTimer,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TilawaButton(
                        text: context.l10n.save,
                        variant: TilawaButtonVariant.ghost,
                        size: TilawaButtonSize.small,
                        onPressed: () {
                          Navigator.of(context).pop(tempDuration);
                        },
                      ),
                    ],
                  ),
                ),
                const TilawaDivider(),
                Expanded(
                  child: _DurationWheelPicker(
                    initialDuration: tempDuration,
                    onDurationChanged: (val) {
                      setSheetState(() {
                        tempDuration = val;
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (picked != null && picked.inSeconds > 0 && context.mounted) {
      context.read<AudioPlayerBloc>().add(
        AudioPlayerEvent.setSleepTimer(picked, type: SleepTimerType.custom),
      );
      context.pop(); // Close main dialog
    }
  }
}

class _DurationWheelPicker extends StatefulWidget {
  const _DurationWheelPicker({
    required this.initialDuration,
    required this.onDurationChanged,
  });
  final Duration initialDuration;
  final ValueChanged<Duration> onDurationChanged;

  @override
  State<_DurationWheelPicker> createState() => _DurationWheelPickerState();
}

class _DurationWheelPickerState extends State<_DurationWheelPicker> {
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _hourController = FixedExtentScrollController(
      initialItem: widget.initialDuration.inHours,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: widget.initialDuration.inMinutes % 60,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _updateDuration() {
    final int hours = _hourController.selectedItem;
    final int minutes = _minuteController.selectedItem;
    widget.onDurationChanged(Duration(hours: hours, minutes: minutes));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Selection Highlight
        Container(
          height: 48,
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(tokens.radiusMedium),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hours
            Expanded(
              child: _buildWheel(
                controller: _hourController,
                itemCount: 24,
                label: context.l10n.hourLabel,
              ),
            ),
            // Minutes
            Expanded(
              child: _buildWheel(
                controller: _minuteController,
                itemCount: 60,
                label: context.l10n.minuteLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String label,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 48,
      perspective: 0.005,
      diameterRatio: 1.2,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (_) => _updateDuration(),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          return Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  index.toString().padLeft(2, '0'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(width: Theme.of(context).tokens.spaceSmall),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
