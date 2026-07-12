import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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

Future<void> openKhatmaReaderAndRefresh(BuildContext context) async {
  await const QuranLastReadRoute().push(context);
  if (!context.mounted) {
    return;
  }
  context.read<KhatmaPlanBloc>().add(const KhatmaPlanStarted());
}
