import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/dedication.dart';
import '../../domain/entities/sadaqah_jariyah_config.dart';
import '../cubit/sadaqah_jariyah_cubit.dart';
import '../cubit/sadaqah_jariyah_state.dart';
import '../widgets/sadaqah_jariyah_add_cta.dart';
import '../widgets/sadaqah_jariyah_add_person_sheet.dart';
import '../widgets/sadaqah_jariyah_list.dart';

class SadaqahJariyahScreen extends StatelessWidget {
  const SadaqahJariyahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SadaqahJariyahCubit, SadaqahJariyahState>(
      builder: (BuildContext context, SadaqahJariyahState state) {
        return TilawaShellChildScaffold(
          appBar: TilawaCatalogAppBar.titleOnly(
            title: context.l10n.sadaqahJariyahIntroP1,
            leading: TilawaAppBarChrome.catalogBackButton(
              context: context,
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
          body: switch (state) {
            SadaqahJariyahLoading() ||
            SadaqahJariyahInitial() => const TilawaLoadingIndicator(),
            SadaqahJariyahError() => TilawaErrorState(
              icon: Icons.favorite_outline,
              title: context.l10n.sadaqahJariyahLoadError,
              retryLabel: context.l10n.retry,
              onRetry: () => context.read<SadaqahJariyahCubit>().load(),
            ),
            SadaqahJariyahLoaded(:final pageData)
                when !pageData.config.featureEnabled =>
              TilawaEmptyState(
                icon: Icons.favorite_outline,
                title: context.l10n.sadaqahJariyahUnavailable,
              ),
            SadaqahJariyahLoaded(
              :final pageData,
              :final photoUrls,
            ) =>
              _LoadedBody(
                config: pageData.config,
                dedications: pageData.dedications,
                photoUrls: photoUrls,
              ),
          },
        );
      },
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.config,
    required this.dedications,
    required this.photoUrls,
  });

  final SadaqahJariyahConfig config;
  final List<Dedication> dedications;
  final Map<String, String?> photoUrls;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceLarge,
              tokens.spaceLarge,
              tokens.spaceLarge,
              tokens.spaceLarge,
            ),
            children: [
              SadaqahJariyahList(
                dedications: dedications,
                photoUrls: photoUrls,
              ),
            ],
          ),
        ),
        TilawaBottomActionArea(
          child: SadaqahJariyahAddCta(
            enabled: true,
            onPressed: () {
              unawaited(
                getIt<AnalyticsService>().logEvent(
                  AnalyticsEvents.sadaqahJariyahCtaTapped,
                ),
              );
              unawaited(
                showSadaqahJariyahAddPersonSheet(
                  context: context,
                  config: config,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
