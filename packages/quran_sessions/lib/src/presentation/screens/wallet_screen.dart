import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Read-only wallet balance and transaction history.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, required this.userId});

  final String userId;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(WalletLoadRequested(userId: widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.walletTitle)),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) => switch (state) {
          WalletInitial() || WalletLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          WalletFailure(:final failure) => Center(
            child: Text(failure.toLocalizedMessage(context)),
          ),
          WalletSuccess(:final wallet, :final transactions) => RefreshIndicator(
            onRefresh: () async {
              context.read<WalletBloc>().add(
                WalletLoadRequested(userId: widget.userId),
              );
              await context.read<WalletBloc>().stream.firstWhere(
                (value) => value is! WalletLoading,
              );
            },
            child: ListView(
              padding: EdgeInsets.all(tokens.spaceLarge),
              children: [
                if (wallet?.isFrozen == true)
                  Padding(
                    padding: EdgeInsets.only(bottom: tokens.spaceMedium),
                    child: TilawaFeedbackStrip(
                      icon: Icons.warning_amber_rounded,
                      message: l10n.walletFrozenMessage,
                      backgroundColor: scheme.warning.withValues(
                        alpha: tokens.opacitySubtle,
                      ),
                      foregroundColor: scheme.warning,
                      variant: TilawaFeedbackVariant.warning,
                    ),
                  ),
                TilawaCard(
                  child: Padding(
                    padding: EdgeInsets.all(tokens.spaceLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.walletAvailableBalanceLabel,
                          style: theme.textTheme.labelLarge,
                        ),
                        SizedBox(height: tokens.spaceSmall),
                        Text(
                          _formatBalance(
                            wallet?.availableBalance ?? 0,
                            wallet?.currency ?? 'EGP',
                          ),
                          style: theme.textTheme.headlineMedium,
                        ),
                        if ((wallet?.heldBalance ?? 0) > 0) ...[
                          SizedBox(height: tokens.spaceSmall),
                          Text(
                            l10n.walletHeldBalanceLabel(
                              _formatBalance(
                                wallet!.heldBalance,
                                wallet.currency,
                              ),
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: tokens.spaceLarge),
                Text(
                  l10n.walletTransactionsTitle,
                  style: theme.textTheme.titleMedium,
                ),
                SizedBox(height: tokens.spaceSmall),
                if (transactions.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: tokens.spaceExtraLarge,
                    ),
                    child: Center(
                      child: Text(
                        l10n.walletEmptyState,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  ...transactions.map(
                    (txn) => Padding(
                      padding: EdgeInsets.only(bottom: tokens.spaceSmall),
                      child: _WalletTransactionTile(transaction: txn),
                    ),
                  ),
              ],
            ),
          ),
        },
      ),
    );
  }

  String _formatBalance(double amount, String currency) {
    final formatter = NumberFormat.currency(
      name: currency,
      symbol: currency == 'EGP' ? 'EGP ' : '$currency ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
}

class _WalletTransactionTile extends StatelessWidget {
  const _WalletTransactionTile({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final isCredit = transaction.direction == WalletTransactionDirection.credit;
    final amountPrefix = isCredit ? '+' : '-';
    final amountColor = isCredit
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return TilawaCard(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: theme.textTheme.bodyLarge,
                  ),
                  SizedBox(height: tokens.spaceSmall),
                  Text(
                    _transactionTypeLabel(context, transaction.type),
                    style: theme.textTheme.bodySmall,
                  ),
                  SizedBox(height: tokens.spaceSmall),
                  Text(
                    DateFormat.yMMMd().add_jm().format(transaction.createdAt),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            Text(
              '$amountPrefix${transaction.amount.toStringAsFixed(2)} ${transaction.currency}',
              style: theme.textTheme.titleSmall?.copyWith(color: amountColor),
            ),
          ],
        ),
      ),
    );
  }

  String _transactionTypeLabel(
    BuildContext context,
    WalletTransactionType type,
  ) {
    final l10n = context.quranSessionsL10n;
    return switch (type) {
      WalletTransactionType.refundCredit => l10n.walletTransactionTypeRefund,
      WalletTransactionType.compensationCredit =>
        l10n.walletTransactionTypeCompensation,
      WalletTransactionType.adminCredit => l10n.walletTransactionTypeAdmin,
      WalletTransactionType.promoCredit => l10n.walletTransactionTypePromo,
      WalletTransactionType.bookingDebit => l10n.walletTransactionTypeBooking,
      WalletTransactionType.hold => l10n.walletTransactionTypeHold,
      WalletTransactionType.holdRelease =>
        l10n.walletTransactionTypeHoldRelease,
      WalletTransactionType.adminReversal => l10n.walletTransactionTypeReversal,
      WalletTransactionType.expiryDebit => l10n.walletTransactionTypeExpiry,
    };
  }
}
