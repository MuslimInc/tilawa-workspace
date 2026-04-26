import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../cubit/player_background_cubit.dart';
import '../cubit/player_background_state.dart';
import '../../domain/entities/player_background_configuration.dart';

class PlayerBackgroundLayer extends StatelessWidget {
  const PlayerBackgroundLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBackgroundCubit, PlayerBackgroundState>(
      builder: (context, state) {
        final config = state.config;

        if (config.type == PlayerBackgroundType.custom &&
            config.customImagePath != null) {
          return TilawaPlayerBackgroundLayer(
            image: FileImage(File(config.customImagePath!)),
            blurAmount: config.blurAmount,
            overlayOpacity: config.overlayOpacity,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
