import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/router/app_router_config.dart';

import '../bloc/khatma_plan_bloc.dart';
import '../bloc/khatma_plan_event.dart';

Future<void> confirmKhatmaPlanReset(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(context.l10n.khatmaResetTitle),
        content: Text(context.l10n.khatmaResetMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.reset),
          ),
        ],
      );
    },
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
