import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/khatma_plan.dart';
import '../../smart_khatma_dependencies.dart';
import '../bloc/khatma_plan_bloc.dart';
import '../bloc/khatma_plan_event.dart';

Future<void> confirmKhatmaPlanReset(BuildContext context) async {
  final confirmed = await showTilawaConfirmDialog(
    context: context,
    title: context.l10n.khatmaResetTitle,
    message: context.l10n.khatmaResetMessage,
    confirmLabel: context.l10n.reset,
    cancelLabel: context.l10n.cancel,
  );
  if (confirmed != true || !context.mounted) {
    return;
  }
  context.read<KhatmaPlanBloc>().add(const KhatmaPlanResetRequested());
}

Future<void> confirmKhatmaExtension(
  BuildContext context,
  KhatmaPlan plan,
) async {
  final DateTime today = DateTime.now();
  final int extraDays = plan.missedDays(today).clamp(1, 30);
  final KhatmaPlan extended = plan.copyWith(
    durationDays: plan.durationDays + extraDays,
  );
  final confirmed = await showTilawaConfirmDialog(
    context: context,
    title: context.l10n.khatmaExtendReviewTitle,
    message: context.l10n.khatmaExtendReviewMessage(
      plan.targetPagesFor(today),
      extended.targetPagesFor(today),
      MaterialLocalizations.of(context).formatMediumDate(
        plan.expectedCompletionDate,
      ),
      MaterialLocalizations.of(context).formatMediumDate(
        extended.expectedCompletionDate,
      ),
    ),
    confirmLabel: context.l10n.khatmaExtendAction,
    cancelLabel: context.l10n.cancel,
  );
  if (confirmed == true && context.mounted) {
    context.read<KhatmaPlanBloc>().add(const KhatmaPlanExtendSelected());
  }
}

Future<void> openKhatmaReaderAndRefresh(
  BuildContext context,
  KhatmaPlan plan,
) async {
  await KhatmaReaderRoute(initialPage: plan.resumePage).push<void>(context);
  if (!context.mounted) {
    return;
  }
  final int visiblePage = await SmartKhatmaDependencies.currentQuranPage();
  if (!context.mounted) return;
  final int minimumPage =
      (plan.confirmedCompletedThroughPage == null
              ? plan.assignmentStartPage
              : plan.confirmedCompletedThroughPage! + 1)
          .clamp(plan.assignmentStartPage, plan.assignmentEndPage);
  final int suggestedPage = visiblePage.clamp(
    minimumPage,
    plan.assignmentEndPage,
  );
  final int? confirmedPage = await showTilawaModalBottomSheet<int>(
    context: context,
    useSafeArea: true,
    builder: (_) => _KhatmaProgressConfirmationSheet(
      minimumPage: minimumPage,
      maximumPage: plan.assignmentEndPage,
      suggestedPage: suggestedPage,
    ),
  );
  if (!context.mounted) return;
  if (confirmedPage != null) {
    context.read<KhatmaPlanBloc>().add(KhatmaProgressConfirmed(confirmedPage));
  } else {
    context.read<KhatmaPlanBloc>().add(const KhatmaPlanStarted());
  }
}

class _KhatmaProgressConfirmationSheet extends StatefulWidget {
  const _KhatmaProgressConfirmationSheet({
    required this.minimumPage,
    required this.maximumPage,
    required this.suggestedPage,
  });

  final int minimumPage;
  final int maximumPage;
  final int suggestedPage;

  @override
  State<_KhatmaProgressConfirmationSheet> createState() =>
      _KhatmaProgressConfirmationSheetState();
}

class _KhatmaProgressConfirmationSheetState
    extends State<_KhatmaProgressConfirmationSheet> {
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.suggestedPage;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bool completesToday = _page == widget.maximumPage;
    return Padding(
      padding: EdgeInsets.all(tokens.spaceLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.spaceMedium,
        children: [
          Text(
            context.l10n.khatmaSaveProgressTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            context.l10n.khatmaCompletedThroughPage(_page),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (widget.minimumPage < widget.maximumPage)
            Semantics(
              label: context.l10n.khatmaProgressPageSelector,
              child: Slider(
                value: _page.toDouble(),
                min: widget.minimumPage.toDouble(),
                max: widget.maximumPage.toDouble(),
                divisions: widget.maximumPage - widget.minimumPage,
                label: '$_page',
                onChanged: (value) => setState(() => _page = value.round()),
              ),
            ),
          TilawaButton(
            text: completesToday
                ? context.l10n.khatmaCompleteTodayAction
                : context.l10n.khatmaSaveThroughPageAction(_page),
            onPressed: () => Navigator.of(context).pop(_page),
          ),
          TilawaButton(
            text: context.l10n.cancel,
            variant: TilawaButtonVariant.outline,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
