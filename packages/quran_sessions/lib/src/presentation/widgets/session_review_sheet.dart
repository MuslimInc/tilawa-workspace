import 'package:flutter/material.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Bottom sheet for submitting a star rating and optional comment.
Future<({int rating, String? comment})?> showSessionReviewSheet(
  BuildContext context, {
  String? teacherName,
}) {
  return showTilawaModalBottomSheet<({int rating, String? comment})>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: TilawaBottomSheetScaffold.modalShape(context),
    builder: (_) => _SessionReviewSheetBody(teacherName: teacherName),
  );
}

class _SessionReviewSheetBody extends StatefulWidget {
  const _SessionReviewSheetBody({this.teacherName});

  final String? teacherName;

  @override
  State<_SessionReviewSheetBody> createState() =>
      _SessionReviewSheetBodyState();
}

class _SessionReviewSheetBodyState extends State<_SessionReviewSheetBody> {
  int _rating = 0;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final teacherName = widget.teacherName?.trim();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: TilawaBottomSheetScaffold(
        topBar: TilawaBottomSheetTitleRow(title: l10n.sessionReviewTitle),
        footer: TilawaBottomSheetActions(
          primaryLabel: l10n.sessionReviewSubmit,
          onPrimary: _rating >= 1 ? _submit : null,
          secondaryLabel: l10n.sessionReviewSkip,
          onSecondary: () => Navigator.pop(context),
        ),
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: TilawaBottomSheetScaffold.resolvedBodyPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    teacherName == null || teacherName.isEmpty
                        ? l10n.sessionReviewSubtitleGeneric
                        : l10n.sessionReviewSubtitle(teacherName),
                  ),
                  SizedBox(height: tokens.spaceLarge),
                  Text(
                    l10n.sessionReviewRatingLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: tokens.spaceSmall),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var star = 1; star <= 5; star++)
                        IconButton(
                          tooltip: l10n.sessionReviewStarLabel(star),
                          onPressed: () => setState(() => _rating = star),
                          icon: Icon(
                            star <= _rating
                                ? TilawaIcons.star
                                : TilawaIcons.starBorder,
                            color: star <= _rating
                                ? scheme.primary
                                : scheme.outline,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: tokens.spaceMedium),
                  TextField(
                    controller: _controller,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: l10n.sessionReviewCommentLabel,
                      hintText: l10n.sessionReviewCommentHint,
                    ),
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
    final comment = _controller.text.trim();
    Navigator.pop(
      context,
      (
        rating: _rating,
        comment: comment.isEmpty ? null : comment,
      ),
    );
  }
}
