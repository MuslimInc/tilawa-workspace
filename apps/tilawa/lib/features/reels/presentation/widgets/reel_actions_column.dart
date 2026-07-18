import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/reel_reaction.dart';

/// Floating action column — react / save / share / more.
class ReelActionsColumn extends StatelessWidget {
  const ReelActionsColumn({
    super.key,
    required this.hasReaction,
    required this.isSaved,
    required this.onReact,
    required this.onSave,
    required this.onShare,
    required this.onMore,
  });

  final bool hasReaction;
  final bool isSaved;
  final VoidCallback onReact;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: hasReaction ? Icons.favorite : Icons.favorite_border,
          color: hasReaction ? scheme.error : Colors.white,
          label: context.l10n.reelsActionReact,
          onTap: onReact,
        ),
        SizedBox(height: tokens.spaceSmall),
        _ActionButton(
          icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
          color: Colors.white,
          label: context.l10n.reelsActionSave,
          onTap: onSave,
        ),
        SizedBox(height: tokens.spaceSmall),
        _ActionButton(
          icon: Icons.ios_share_rounded,
          color: Colors.white,
          label: context.l10n.reelsActionShare,
          onTap: onShare,
        ),
        SizedBox(height: tokens.spaceSmall),
        _ActionButton(
          icon: Icons.more_horiz,
          color: Colors.white,
          label: context.l10n.reelsActionMore,
          onTap: onMore,
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0.88,
    upperBound: 1,
    value: 1,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.reverse();
    await _controller.forward();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ScaleTransition(
      scale: _controller,
      child: InkWell(
        onTap: _handleTap,
        customBorder: const CircleBorder(),
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceSmall),
                child: Icon(widget.icon, color: widget.color, size: 28),
              ),
            ),
            SizedBox(height: tokens.spaceSmall / 2),
            Text(
              widget.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet to pick one of four Islamic reactions.
Future<ReelReaction?> showReelReactionPicker(BuildContext context) {
  final l10n = context.l10n;
  final tokens = context.tokens;
  return showModalBottomSheet<ReelReaction>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceMedium,
            tokens.spaceSmall,
            tokens.spaceMedium,
            tokens.spaceMedium,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.reelsReactionsTitle,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              SizedBox(height: tokens.spaceMedium),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: tokens.spaceSmall,
                crossAxisSpacing: tokens.spaceSmall,
                childAspectRatio: 2.8,
                children: [
                  for (final reaction in ReelReaction.values)
                    TilawaChip(
                      label: _reactionLabel(l10n, reaction),
                      onTap: () => Navigator.of(ctx).pop(reaction),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _reactionLabel(AppLocalizations l10n, ReelReaction reaction) {
  return switch (reaction) {
    ReelReaction.loved => l10n.reelsReactionLoved,
    ReelReaction.allahummaTaqabbal => l10n.reelsReactionAllahummaTaqabbal,
    ReelReaction.subhanAllah => l10n.reelsReactionSubhanAllah,
    ReelReaction.mashaAllah => l10n.reelsReactionMashaAllah,
  };
}
