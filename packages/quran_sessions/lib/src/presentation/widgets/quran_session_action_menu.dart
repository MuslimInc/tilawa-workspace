import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

enum _QuranSessionAction { viewDetails, reschedule, cancel }

/// Overflow menu for secondary session actions on student session cards.
class QuranSessionActionMenu extends StatefulWidget {
  const QuranSessionActionMenu({
    super.key,
    this.onViewDetails,
    this.onReschedule,
    this.onCancel,
  });

  final VoidCallback? onViewDetails;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;

  bool get _hasActions =>
      onViewDetails != null || onReschedule != null || onCancel != null;

  @override
  State<QuranSessionActionMenu> createState() => _QuranSessionActionMenuState();
}

class _QuranSessionActionMenuState extends State<QuranSessionActionMenu> {
  final _anchorKey = GlobalKey();

  Future<void> _openMenu() async {
    if (_anchorKey.currentContext == null) return;

    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;
    final menuWidth = tokens.spaceXXL * 5;

    final action = await showMenu<_QuranSessionAction>(
      context: context,
      useRootNavigator: true,
      positionBuilder: (menuContext, constraints) {
        final anchorBox =
            _anchorKey.currentContext!.findRenderObject()! as RenderBox;
        final overlayBox =
            Overlay.of(menuContext).context.findRenderObject()! as RenderBox;
        final topLeft = anchorBox.localToGlobal(
          Offset.zero,
          ancestor: overlayBox,
        );
        final top = topLeft.dy + anchorBox.size.height + tokens.spaceExtraSmall;
        final isRtl = Directionality.of(menuContext) == TextDirection.rtl;
        final iconLeft = topLeft.dx;
        final iconRight = iconLeft + anchorBox.size.width;

        final menuLeft = switch ((isRtl, iconRight - menuWidth < 0)) {
          (true, true) => iconLeft,
          (true, false) => iconRight - menuWidth,
          (false, _) when iconLeft + menuWidth > overlayBox.size.width =>
            iconRight - menuWidth,
          (false, _) => iconLeft,
        };

        return RelativeRect.fromLTRB(
          menuLeft,
          top,
          overlayBox.size.width - menuLeft - menuWidth,
          overlayBox.size.height - top,
        );
      },
      constraints: BoxConstraints.tightFor(width: menuWidth),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      items: [
        if (widget.onViewDetails != null)
          PopupMenuItem(
            value: _QuranSessionAction.viewDetails,
            child: Text(l10n.viewSessionDetails),
          ),
        if (widget.onReschedule != null)
          PopupMenuItem(
            value: _QuranSessionAction.reschedule,
            child: Text(l10n.rescheduleAction),
          ),
        if (widget.onCancel != null)
          PopupMenuItem(
            value: _QuranSessionAction.cancel,
            child: Text(
              l10n.cancelSessionAction,
              style: TextStyle(color: scheme.error),
            ),
          ),
      ],
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _QuranSessionAction.viewDetails:
        widget.onViewDetails?.call();
      case _QuranSessionAction.reschedule:
        widget.onReschedule?.call();
      case _QuranSessionAction.cancel:
        widget.onCancel?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget._hasActions) return const SizedBox.shrink();

    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: l10n.sessionCardOverflowMenu,
      child: IconButton(
        key: _anchorKey,
        onPressed: _openMenu,
        icon: Icon(
          Icons.more_vert,
          size: tokens.iconSizeSmall,
          color: scheme.onSurfaceVariant,
        ),
        tooltip: l10n.sessionCardOverflowMenu,
        style: IconButton.styleFrom(
          fixedSize: Size.square(tokens.minInteractiveDimension),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
