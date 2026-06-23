import 'package:flutter/material.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Bottom sheet for filing a session safety / abuse report.
Future<({SessionReportCategory category, String description})?>
showReportConcernSheet(
  BuildContext context,
) {
  return showTilawaModalBottomSheet<
    ({SessionReportCategory category, String description})
  >(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: TilawaBottomSheetScaffold.modalShape(context),
    builder: (_) => const _ReportConcernSheetBody(),
  );
}

class _ReportConcernSheetBody extends StatefulWidget {
  const _ReportConcernSheetBody();

  @override
  State<_ReportConcernSheetBody> createState() =>
      _ReportConcernSheetBodyState();
}

class _ReportConcernSheetBodyState extends State<_ReportConcernSheetBody> {
  SessionReportCategory _category = SessionReportCategory.safetyConcern;
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: TilawaBottomSheetScaffold(
        topBar: TilawaBottomSheetTitleRow(title: l10n.reportConcernTitle),
        footer: TilawaBottomSheetActions(
          primaryLabel: l10n.reportConcernSubmit,
          onPrimary: _submit,
          secondaryLabel: l10n.reportConcernCancel,
          onSecondary: () => Navigator.pop(context),
        ),
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: TilawaBottomSheetScaffold.resolvedBodyPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.reportConcernSubtitle),
                  SizedBox(height: tokens.spaceLarge),
                  DropdownButtonFormField<SessionReportCategory>(
                    initialValue: _category,
                    decoration: InputDecoration(
                      labelText: l10n.reportConcernCategory,
                    ),
                    items: SessionReportCategory.values
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(_categoryLabel(l10n, category)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _category = value);
                      }
                    },
                  ),
                  SizedBox(height: tokens.spaceMedium),
                  TextField(
                    controller: _controller,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: l10n.reportConcernDescriptionLabel,
                      hintText: l10n.reportConcernDescriptionHint,
                      errorText: _error,
                    ),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final description = _controller.text.trim();
    if (description.length < ReportSessionConcernUseCase.minDescriptionLength) {
      setState(
        () =>
            _error = context.quranSessionsL10n.reportConcernDescriptionTooShort,
      );
      return;
    }
    Navigator.pop(
      context,
      (category: _category, description: description),
    );
  }

  String _categoryLabel(dynamic l10n, SessionReportCategory category) {
    return switch (category) {
      SessionReportCategory.safetyConcern => l10n.reportCategorySafetyConcern,
      SessionReportCategory.abuseOrHarassment =>
        l10n.reportCategoryAbuseOrHarassment,
      SessionReportCategory.inappropriateContent =>
        l10n.reportCategoryInappropriateContent,
      SessionReportCategory.childSafety => l10n.reportCategoryChildSafety,
      SessionReportCategory.fraudOrScam => l10n.reportCategoryFraudOrScam,
      SessionReportCategory.other => l10n.reportCategoryOther,
    };
  }
}
