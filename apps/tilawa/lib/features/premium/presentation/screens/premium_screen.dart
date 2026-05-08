import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../shared/widgets/quran_player_widget.dart';
import '../../../../shared/widgets/tilawa_back_button.dart';
import '../../domain/entities/premium_status.dart';
import '../../domain/entities/subscription_plan.dart';
import '../bloc/premium_bloc.dart';
import '../bloc/premium_event.dart';
import '../bloc/premium_state.dart';
import '../widgets/subscription_plan_card.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PremiumBloc>().add(const LoadPremiumStatus());
    context.read<PremiumBloc>().add(const LoadAvailablePlans());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: context.canPop() ? const TilawaBackButton() : null,
            title: Text(context.l10n.premium),
          ),
          body: BlocConsumer<PremiumBloc, PremiumState>(
            listener: (context, state) {
              state.when(
                initial: () {},
                loading: () {},
                loaded: (status, plans, canDownload) {},
                error: (message) {
                  ToastUtils.showErrorToast(message);
                },
                purchaseSuccess: (message) {
                  ToastUtils.showSuccessToast(message);
                },
                purchaseFailed: (message) {
                  ToastUtils.showErrorToast(message);
                },
                trialStarted: (message) {
                  ToastUtils.showSuccessToast(message);
                },
                trialNotEligible: (message) {
                  ToastUtils.showToast(
                    msg: message,
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                  );
                },
              );
            },
            builder: (context, state) {
              return state.when(
                initial: () => const Center(child: CircularProgressIndicator()),
                loading: () => const Center(child: CircularProgressIndicator()),
                loaded: (status, plans, canDownload) =>
                    _buildLoadedContent(context, status, plans, canDownload),
                error: (message) => _buildErrorContent(context, message),
                purchaseSuccess: (message) =>
                    _buildSuccessContent(context, message),
                purchaseFailed: (message) =>
                    _buildErrorContent(context, message),
                trialStarted: (message) =>
                    _buildSuccessContent(context, message),
                trialNotEligible: (message) =>
                    _buildErrorContent(context, message),
              );
            },
          ),
        ),
        const Positioned.fill(child: QuranPlayerWidget()),
      ],
    );
  }

  Widget _buildLoadedContent(
    BuildContext context,
    PremiumStatus status,
    List<SubscriptionPlan> plans,
    bool canDownload,
  ) {
    final tokens = Theme.of(context).tokens;

    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spaceLarge).copyWith(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(context, status, canDownload),
          SizedBox(height: tokens.spaceExtraLarge),
          _buildFeaturesSection(context),
          SizedBox(height: tokens.spaceExtraLarge),
          _buildPlansSection(context, plans),
          SizedBox(height: tokens.spaceExtraLarge),
          if (!status.isTrialUsed && !status.isSubscriptionActive)
            _buildTrialSection(context),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    PremiumStatus status,
    bool canDownload,
  ) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final accent = canDownload ? colorScheme.primary : colorScheme.tertiary;
    final container = canDownload
        ? colorScheme.primaryContainer
        : colorScheme.tertiaryContainer;
    final onContainer = canDownload
        ? colorScheme.onPrimaryContainer
        : colorScheme.onTertiaryContainer;

    return Card(
      elevation: 0,
      color: container,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        side: BorderSide(
          color: accent.withValues(alpha: tokens.opacitySubtle),
          width: tokens.borderWidthThin,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  canDownload ? Icons.star_rounded : Icons.star_border_rounded,
                  color: accent,
                  size: tokens.iconSizeLarge,
                ),
                SizedBox(width: tokens.spaceSmall),
                Expanded(
                  child: Text(
                    status.statusText,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: onContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spaceSmall),
            if (status.daysRemaining > 0)
              Text(
                context.l10n.daysRemaining(status.daysRemaining),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: onContainer.withValues(alpha: tokens.opacityEmphasis),
                ),
              ),
            Text(
              canDownload
                  ? context.l10n.premiumAccessMessage
                  : context.l10n.upgradeMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onContainer.withValues(alpha: tokens.opacityEmphasis),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.premiumFeatures,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: tokens.spaceMedium),
        _PremiumFeatureItem(
          icon: Icons.download_rounded,
          text: context.l10n.unlimitedDownloads,
        ),
        _PremiumFeatureItem(
          icon: Icons.offline_bolt_rounded,
          text: context.l10n.offlineMode,
        ),
        _PremiumFeatureItem(
          icon: Icons.high_quality_rounded,
          text: context.l10n.highQualityAudio,
        ),
        _PremiumFeatureItem(
          icon: Icons.block_rounded,
          text: context.l10n.adFreeExperience,
        ),
        _PremiumFeatureItem(
          icon: Icons.support_agent_rounded,
          text: context.l10n.prioritySupport,
        ),
        _PremiumFeatureItem(
          icon: Icons.star_rounded,
          text: context.l10n.exclusiveContent,
        ),
      ],
    );
  }

  Widget _buildPlansSection(
    BuildContext context,
    List<SubscriptionPlan> plans,
  ) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.chooseYourPlan,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: tokens.spaceMedium),
        ...plans.map(
          (plan) => SubscriptionPlanCard(
            plan: plan,
            onSelect: () => _purchasePlan(context, plan.id),
          ),
        ),
      ],
    );
  }

  Widget _buildTrialSection(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: tokens.opacityMedium,
          ),
          width: tokens.borderWidthThin,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.free_breakfast_rounded,
                  color: colorScheme.primary,
                  size: tokens.iconSizeMedium,
                ),
                SizedBox(width: tokens.spaceSmall),
                Expanded(
                  child: Text(
                    context.l10n.freeTrialTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spaceSmall),
            Text(
              context.l10n.freeTrialDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: tokens.spaceMedium),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _startTrial(context),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(context.l10n.startFreeTrial),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, String message) {
    return TilawaErrorState(
      icon: Icons.error_outline_rounded,
      title: message,
      retryLabel: context.l10n.retry,
      onRetry: () {
        context.read<PremiumBloc>().add(const LoadPremiumStatus());
      },
    );
  }

  Widget _buildSuccessContent(BuildContext context, String message) {
    return TilawaEmptyState(
      icon: Icons.check_circle_outline_rounded,
      iconColor: Theme.of(context).colorScheme.primary,
      title: message,
      action: ElevatedButton(
        onPressed: () {
          context.read<PremiumBloc>().add(const LoadPremiumStatus());
        },
        child: Text(context.l10n.continueButton),
      ),
    );
  }

  void _purchasePlan(BuildContext context, String planId) {
    context.read<PremiumBloc>().add(PurchaseSubscription(planId: planId));
  }

  void _startTrial(BuildContext context) {
    context.read<PremiumBloc>().add(const StartTrial());
  }
}

class _PremiumFeatureItem extends StatelessWidget {
  const _PremiumFeatureItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spaceExtraSmall),
      child: Row(
        children: [
          Icon(
            icon,
            size: tokens.iconSizeMedium,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: tokens.spaceMedium),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
