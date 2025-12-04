import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
      body: BlocConsumer<PremiumBloc, PremiumState>(
        listener: (context, state) {
          state.when(
            initial: () {},
            loading: () {},
            loaded: (status, plans, canDownload) {},
            error: (message) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            },
            purchaseSuccess: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message), backgroundColor: Colors.green),
              );
            },
            purchaseFailed: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message), backgroundColor: Colors.red),
              );
            },
            trialStarted: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message), backgroundColor: Colors.green),
              );
            },
            trialNotEligible: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.orange,
                ),
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
            purchaseFailed: (message) => _buildErrorContent(context, message),
            trialStarted: (message) => _buildSuccessContent(context, message),
            trialNotEligible: (message) => _buildErrorContent(context, message),
          );
        },
      ),
    );
  }

  Widget _buildLoadedContent(
    BuildContext context,
    PremiumStatus status,
    List<SubscriptionPlan> plans,
    bool canDownload,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Status Card
          _buildStatusCard(context, status, canDownload),
          const SizedBox(height: 24),

          // Premium Features
          _buildFeaturesSection(),
          const SizedBox(height: 24),

          // Subscription Plans
          _buildPlansSection(context, plans),
          const SizedBox(height: 24),

          // Trial Section
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: canDownload
                ? [Colors.green.shade400, Colors.green.shade600]
                : [Colors.amber.shade400, Colors.amber.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  canDownload ? Icons.star : Icons.star_border,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  status.statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (status.daysRemaining > 0)
              Text(
                '${status.daysRemaining} days remaining',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            if (canDownload)
              const Text(
                'You have access to all premium features!',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              )
            else
              const Text(
                'Upgrade to unlock premium features',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Premium Features',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        _PremiumFeatureItem(icon: Icons.download, text: 'Unlimited Downloads'),
        _PremiumFeatureItem(icon: Icons.offline_bolt, text: 'Offline Mode'),
        _PremiumFeatureItem(
          icon: Icons.high_quality,
          text: 'High Quality Audio',
        ),
        _PremiumFeatureItem(icon: Icons.block, text: 'Ad-Free Experience'),
        _PremiumFeatureItem(
          icon: Icons.support_agent,
          text: 'Priority Support',
        ),
        _PremiumFeatureItem(icon: Icons.star, text: 'Exclusive Content'),
      ],
    );
  }

  Widget _buildPlansSection(
    BuildContext context,
    List<SubscriptionPlan> plans,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Your Plan',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.free_breakfast, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  '7-Day Free Trial',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Try all premium features for 7 days, completely free!',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startTrial(context),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Free Trial'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<PremiumBloc>().add(const LoadPremiumStatus());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<PremiumBloc>().add(const LoadPremiumStatus());
            },
            child: const Text('Continue'),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}
