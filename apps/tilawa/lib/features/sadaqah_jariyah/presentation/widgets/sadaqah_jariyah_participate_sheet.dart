import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/sadaqah_jariyah_config.dart';
import '../../domain/usecases/build_whatsapp_participate_uri_use_case.dart';

Future<void> showSadaqahJariyahParticipateSheet({
  required BuildContext context,
  required SadaqahJariyahConfig config,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      return SadaqahJariyahParticipateSheet(config: config);
    },
  );
}

class SadaqahJariyahParticipateSheet extends StatefulWidget {
  const SadaqahJariyahParticipateSheet({required this.config, super.key});

  final SadaqahJariyahConfig config;

  @override
  State<SadaqahJariyahParticipateSheet> createState() =>
      _SadaqahJariyahParticipateSheetState();
}

class _SadaqahJariyahParticipateSheetState
    extends State<SadaqahJariyahParticipateSheet> {
  bool _launchFailed = false;
  bool _launching = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final l10n = context.l10n;
    final String languageCode = Localizations.localeOf(context).languageCode;
    final String template = widget.config.messageTemplateForLanguageCode(
      languageCode,
    );
    final bool hasPhone = widget.config.whatsappE164
        .replaceAll(RegExp(r'[^\d]'), '')
        .isNotEmpty;
    final bool showFallback = _launchFailed || !hasPhone;

    return TilawaBottomSheetScaffold(
      topBar: TilawaBottomSheetTitleRow(title: l10n.sadaqahJariyahSheetTitle),
      footer: TilawaBottomSheetActions(
        primaryLabel: showFallback
            ? l10n.sadaqahJariyahCopyMessage
            : l10n.sadaqahJariyahContinueWhatsapp,
        primaryLoading: _launching,
        onPrimary: _launching
            ? null
            : () async {
                if (showFallback) {
                  await Clipboard.setData(ClipboardData(text: template));
                  if (!context.mounted) {
                    return;
                  }
                  TilawaFeedback.showToast(
                    context,
                    message: l10n.sadaqahJariyahMessageCopied,
                    variant: TilawaFeedbackVariant.success,
                  );
                  return;
                }
                await _openWhatsApp();
              },
        secondaryLabel: l10n.sadaqahJariyahNotNow,
        onSecondary: () => Navigator.of(context).maybePop(),
      ),
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: TilawaBottomSheetScaffold.resolvedBodyPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.sadaqahJariyahIntentionLine,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: tokens.textHeightLoose,
                  ),
                ),
                SizedBox(height: tokens.spaceMedium),
                Text(
                  l10n.sadaqahJariyahSheetChecklist,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: tokens.textHeightLoose,
                  ),
                ),
                if (showFallback) ...[
                  SizedBox(height: tokens.spaceMedium),
                  Text(
                    l10n.sadaqahJariyahWhatsappUnavailable,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (widget.config.whatsappE164.trim().isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: tokens.spaceExtraSmall),
                      child: SelectableText(widget.config.whatsappE164.trim()),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openWhatsApp() async {
    setState(() => _launching = true);
    final result = await getIt<BuildWhatsappParticipateUriUseCase>()(
      BuildWhatsappParticipateUriParams(
        config: widget.config,
        languageCode: Localizations.localeOf(context).languageCode,
      ),
    );
    final bool opened = await result.fold(
      (_) async => false,
      (Uri uri) async {
        try {
          return await launchUrl(uri, mode: LaunchMode.externalApplication);
        } on Object {
          return false;
        }
      },
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _launching = false;
      if (!opened) {
        _launchFailed = true;
      } else {
        unawaited(Navigator.of(context).maybePop());
      }
    });
  }
}
