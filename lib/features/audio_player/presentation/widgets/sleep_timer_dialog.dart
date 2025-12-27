import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions.dart';
import '../bloc/audio_player_bloc.dart';

class SleepTimerDialog extends StatelessWidget {
  const SleepTimerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.sleepTimer,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),
            _buildOption(
              context,
              context.l10n.minutes15,
              const Duration(minutes: 15),
            ),
            _buildOption(
              context,
              context.l10n.minutes30,
              const Duration(minutes: 30),
            ),
            _buildOption(
              context,
              context.l10n.minutes60,
              const Duration(minutes: 60),
            ),
            // _buildOption(context, '120 Minutes', const Duration(minutes: 120)),
            Divider(height: 30.h),
            _buildCustomOption(context),
            SizedBox(height: 10.h),
            BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
              builder: (context, state) {
                if (!state.isSleepTimerActive) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () {
                    context.read<AudioPlayerBloc>().add(
                      const AudioPlayerEvent.cancelSleepTimer(),
                    );
                    context.pop();
                  },
                  child: Text(
                    context.l10n.cancelTimer,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String label, Duration duration) {
    return ListTile(
      title: Text(label, style: TextStyle(fontSize: 16.sp)),
      onTap: () {
        context.read<AudioPlayerBloc>().add(
          AudioPlayerEvent.setSleepTimer(duration),
        );
        context.pop();
      },
      trailing: const Icon(Icons.timer_outlined),
    );
  }

  Widget _buildCustomOption(BuildContext context) {
    return ListTile(
      title: Text(context.l10n.custom, style: TextStyle(fontSize: 16.sp)),
      trailing: const Icon(Icons.edit_outlined),
      onTap: () async {
        // Show CupertinoTimerPicker
        final Duration? picked = await showModalBottomSheet<Duration>(
          context: context,
          builder: (BuildContext context) {
            var tempDuration = const Duration(minutes: 15);
            return Container(
              height: 300.h,
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text(context.l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => context.pop(tempDuration),
                        child: Text(context.l10n.save),
                      ),
                    ],
                  ),
                  Expanded(
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      initialTimerDuration: tempDuration,
                      onTimerDurationChanged: (Duration newDuration) {
                        tempDuration = newDuration;
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );

        if (picked != null && picked.inSeconds > 0 && context.mounted) {
          context.read<AudioPlayerBloc>().add(
            AudioPlayerEvent.setSleepTimer(picked),
          );
          context.pop(); // Close the main dialog
        }
      },
    );
  }
}
