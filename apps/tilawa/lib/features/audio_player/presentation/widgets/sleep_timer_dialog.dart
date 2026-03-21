import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:tilawa/core/extensions.dart';
import '../../../../shared/models/position_data.dart';
import '../bloc/audio_player_bloc.dart';

class SleepTimerDialog extends StatelessWidget {
  const SleepTimerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: EdgeInsets.all(24),
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (state.isSleepTimerActive)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer,
                              size: 14,
                              color: Theme.of(context).primaryColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              context.l10n.sleepTimerActive,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 24),

                // Options Grid
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildTimerChip(
                      context,
                      context.l10n.minutes15,
                      const Duration(minutes: 15),
                      state,
                    ),
                    _buildTimerChip(
                      context,
                      context.l10n.minutes30,
                      const Duration(minutes: 30),
                      state,
                    ),
                    _buildTimerChip(
                      context,
                      context.l10n.minutes60,
                      const Duration(minutes: 60),
                      state,
                    ),
                    _buildEndTrackChip(context, state),
                    _buildCustomChip(context, state),
                  ],
                ),

                SizedBox(height: 24),

                // Cancel Button
                if (state.isSleepTimerActive)
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<AudioPlayerBloc>().add(
                        const AudioPlayerEvent.cancelSleepTimer(),
                      );
                      context.pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.timer_off_outlined),
                    label: Text(context.l10n.cancelTimer),
                  )
                else
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(context.l10n.cancel),
                  ),
              ],
            );
          },
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

    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : null,
          fontWeight: isActive ? FontWeight.bold : null,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: isActive
          ? Theme.of(context).primaryColor
          : Theme.of(context).cardColor,
      side: BorderSide(
        color: isActive
            ? Theme.of(context).primaryColor
            : Theme.of(context).dividerColor.withValues(alpha: 0.5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

    return ActionChip(
      label: Text(
        context.l10n.endOfTrack,
        style: TextStyle(
          color: isActive ? Colors.white : null,
          fontWeight: isActive ? FontWeight.bold : null,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: isActive
          ? Theme.of(context).primaryColor
          : Theme.of(context).cardColor,
      side: BorderSide(
        color: isActive
            ? Theme.of(context).primaryColor
            : Theme.of(context).dividerColor.withValues(alpha: 0.5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      avatar: canUse
          ? Icon(
              Icons.skip_next,
              size: 16,
              color: isActive ? Colors.white : null,
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

    return ActionChip(
      label: Text(
        context.l10n.custom,
        style: TextStyle(
          color: isActive ? Colors.white : null,
          fontWeight: isActive ? FontWeight.bold : null,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: isActive
          ? Theme.of(context).primaryColor
          : Theme.of(context).cardColor,
      side: BorderSide(
        color: isActive
            ? Theme.of(context).primaryColor
            : Theme.of(context).dividerColor.withValues(alpha: 0.5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      avatar: Icon(
        Icons.edit_outlined,
        size: 16,
        color: isActive ? Colors.white : null,
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

    final Duration? picked = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: Colors.transparent, // For custom container shape
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: 350,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Actions
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text(context.l10n.cancel),
                      ),
                      Text(
                        context.l10n.setTimer,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(tempDuration);
                        },
                        child: Text(context.l10n.save),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
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
    return Stack(
      alignment: Alignment.center,
      children: [
        // Selection Highlight
        Container(
          height: 48,
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
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
