import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/dedication.dart';
import '../../domain/entities/sadaqah_jariyah_config.dart';
import '../cubit/sadaqah_jariyah_cubit.dart';
import '../cubit/sadaqah_jariyah_state.dart';
import '../widgets/sadaqah_jariyah_footer.dart';
import '../widgets/sadaqah_jariyah_intro.dart';
import '../widgets/sadaqah_jariyah_list.dart';
import '../widgets/sadaqah_jariyah_participate_sheet.dart';
import '../widgets/sadaqah_jariyah_support_cta.dart';

class SadaqahJariyahScreen extends StatelessWidget {
  const SadaqahJariyahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SadaqahJariyahCubit, SadaqahJariyahState>(
      builder: (BuildContext context, SadaqahJariyahState state) {
        final String languageCode = Localizations.localeOf(
          context,
        ).languageCode;
        final String title = switch (state) {
          SadaqahJariyahLoaded(:final pageData) =>
            pageData.config.titleForLanguageCode(languageCode),
          _ => context.l10n.sadaqahJariyahDefaultTitle,
        };

        return TilawaShellChildScaffold(
          appBar: TilawaCatalogAppBar.titleOnly(
            title: title,
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
    final bool ctaEnabled = config.featureEnabled;

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
              SadaqahJariyahIntro(config: config),
              SizedBox(height: tokens.spaceExtraLarge),
              SadaqahJariyahList(
                dedications: dedications,
                photoUrls: photoUrls,
              ),
              SizedBox(height: tokens.spaceLarge),
              const SadaqahJariyahFooter(),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceLarge,
              tokens.spaceSmall,
              tokens.spaceLarge,
              tokens.spaceMedium,
            ),
            child: SadaqahJariyahSupportCta(
              enabled: ctaEnabled,
              onPressed: () {
                unawaited(context.read<SadaqahJariyahCubit>().logCtaTapped());
                unawaited(
                  showSadaqahJariyahParticipateSheet(
                    context: context,
                    config: config,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
