import 'package:flutter/material.dart';
import 'package:quran_sessions/quran_sessions.dart';

/// Bottom sheet for filing a session safety / abuse report.
Future<({SessionReportCategory category, String description})?>
showReportConcernSheet(
  BuildContext context,
) {
  return showModalBottomSheet<
    ({SessionReportCategory category, String description})
  >(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const _ReportConcernSheetBody(),
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.reportConcernTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(l10n.reportConcernSubtitle),
          const SizedBox(height: 16),
          DropdownButtonFormField<SessionReportCategory>(
            initialValue: _category,
            decoration: InputDecoration(labelText: l10n.reportConcernCategory),
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.reportConcernCancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(l10n.reportConcernSubmit),
                ),
              ),
            ],
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
