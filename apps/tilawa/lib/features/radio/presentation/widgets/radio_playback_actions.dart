import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/audio_player/presentation/widgets/sleep_timer_dialog.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_core/entities/audio.dart';

import '../../domain/entities/radio_station.dart';
import '../cubit/radio_cubit.dart';

/// Shared play / share helpers for radio presentation.
abstract final class RadioPlaybackActions {
  static String apiLanguage(BuildContext context) {
    final String code = Localizations.localeOf(context).languageCode;
    return code == 'ar' ? 'ar' : 'eng';
  }

  static Future<void> play(
    BuildContext context,
    RadioStation station,
  ) async {
    final RadioCubit cubit = context.read<RadioCubit>();
    final AudioEntity audio = await cubit.playStation(station);
    if (!context.mounted) return;
    context.read<AudioPlayerBloc>().add(
      AudioPlayerEvent.playFromQueue([audio], 0),
    );
  }

  static Future<void> share(
    BuildContext context,
    RadioStation station,
  ) async {
    await context.read<RadioCubit>().trackShare(station);
    final String text = context.l10n.radioShareText(
      station.name,
      station.streamUrl,
    );
    await SharePlus.instance.share(ShareParams(text: text));
  }

  static Future<void> stop(BuildContext context) async {
    await context.read<RadioCubit>().trackStop();
    if (!context.mounted) return;
    context.read<AudioPlayerBloc>().add(const AudioPlayerEvent.stopAudio());
  }

  static void openFullPlayer(BuildContext context, RadioStation station) {
    RadioPlayerRoute(stationId: station.id).push<void>(context);
  }

  static void showSleepTimer(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const SleepTimerDialog(),
    );
  }
}
