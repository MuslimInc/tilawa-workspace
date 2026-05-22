import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/support_product.dart';
import '../bloc/support_bloc.dart';
import '../bloc/support_event.dart';
import '../bloc/support_state.dart';
import '../widgets/support_confirmation_sheet.dart';
import '../widgets/support_impact_section.dart';
import '../widgets/support_thank_you_view.dart';
import '../widgets/support_tier_selector.dart';

/// Voluntary one-time support for Tilawa via Google Play.
class SupportTilawaScreen extends StatefulWidget {
  const SupportTilawaScreen({super.key});

  @override
  State<SupportTilawaScreen> createState() => _SupportTilawaScreenState();
}

class _SupportTilawaScreenState extends State<SupportTilawaScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<SupportBloc>().add(const SupportEvent.appResumed());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TilawaAppBar(title: context.l10n.supportTilawa),
      body: BlocConsumer<SupportBloc, SupportState>(
        listenWhen: (SupportState prev, SupportState next) =>
            prev.failure != next.failure && next.failure != null,
        listener: (BuildContext context, SupportState state) {
          final Failure? failure = state.failure;
          if (failure == null) {
            return;
          }
          final String? message = failure.localizedMessage(context);
          if (message != null) {
            ToastUtils.showErrorToast(message);
          }
        },
        builder: (BuildContext context, SupportState state) {
          final l10n = context.l10n;

          if (state.purchasePhase == SupportPurchasePhase.thanked) {
            return SupportThankYouView(
              onDone: () => context.read<SupportBloc>().add(
                const SupportEvent.thankYouDismissed(),
              ),
            );
          }

          if (state.status == SupportStatus.loading) {
            return const Center(child: TilawaLoadingIndicator());
          }

          if (state.isOffline) {
            return TilawaErrorState(
              icon: FluentIcons.wifi_off_24_regular,
              title: l10n.supportOfflineMessage,
              onRetry: () => context.read<SupportBloc>().add(
                const SupportEvent.started(),
              ),
            );
          }

          if (state.status == SupportStatus.error && state.products.isEmpty) {
            return TilawaErrorState(
              icon: FluentIcons.error_circle_24_regular,
              title:
                  state.failure?.localizedMessage(context) ??
                  l10n.supportProductsUnavailable,
              onRetry: () => context.read<SupportBloc>().add(
                const SupportEvent.started(),
              ),
            );
          }

          return _SupportBody(state: state);
        },
      ),
    );
  }
}

class _SupportBody extends StatelessWidget {
  const _SupportBody({required this.state});

  final SupportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final bool purchasing =
        state.purchasePhase == SupportPurchasePhase.purchasing;

    return TilawaContentBounds(
      kind: TilawaContentKind.form,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLarge,
          tokens.spaceLarge,
          tokens.spaceLarge,
          tokens.spaceExtraLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceLarge + tokens.spaceSmall,
          children: [
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(tokens.radiusLarge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: tokens.spaceSmall,
                children: [
                  Text(
                    l10n.supportTilawaSubtitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l10n.supportMissionBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: tokens.textHeightLoose,
                    ),
                  ),
                ],
              ),
            ),
            const SupportImpactSection(),
            SupportTierSelector(
              products: state.products,
              selectedProductId: state.selectedProductId,
              onSelected: (String id) => context.read<SupportBloc>().add(
                SupportEvent.tierSelected(id),
              ),
            ),
            TilawaButton(
              text: l10n.supportContinueWithPlay,
              isLoading: purchasing,
              onPressed: state.selectedProductId == null || purchasing
                  ? null
                  : () => _onContinue(context, state),
            ),
            TextButton(
              onPressed: purchasing
                  ? null
                  : () => context.read<SupportBloc>().add(
                      const SupportEvent.restoreRequested(),
                    ),
              child: Text(l10n.supportRestorePurchases),
            ),
            Text(
              l10n.supportRestoreHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              l10n.supportPlayFooter,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              l10n.supportDisclaimer,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onContinue(BuildContext context, SupportState state) async {
    final String? productId = state.selectedProductId;
    if (productId == null) {
      return;
    }
    final SupportProduct product = state.products.firstWhere(
      (SupportProduct p) => p.id == productId,
    );

    context.read<SupportBloc>().add(const SupportEvent.continuePressed());

    final bool? confirmed = await showSupportConfirmationSheet(
      context,
      product: product,
    );

    if (!context.mounted) {
      return;
    }

    if (confirmed == true) {
      context.read<SupportBloc>().add(
        const SupportEvent.purchaseConfirmed(),
      );
    } else {
      context.read<SupportBloc>().add(
        const SupportEvent.purchaseDismissed(),
      );
    }
  }
}
