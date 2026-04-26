import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/athkar_item.dart';
import 'item_count_widget.dart';

class AthkarItemWidget extends StatefulWidget {
  const AthkarItemWidget({
    super.key,
    required this.item,
    required this.currentCount,
    required this.onTap,
    required this.onReset,
  });

  final AthkarItem item;
  final int currentCount;
  final VoidCallback onTap;
  final VoidCallback onReset;

  @override
  State<AthkarItemWidget> createState() => _AthkarItemWidgetState();
}

class _AthkarItemWidgetState extends State<AthkarItemWidget> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AthkarItem item = widget.item;
    final int currentCount = widget.currentCount;
    final VoidCallback onTap = widget.onTap;
    final VoidCallback onReset = widget.onReset;
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    final isDone = currentCount == 0;
    final ThemeData theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      behavior: HitTestBehavior.translucent,
      child: Center(
        child: GestureDetector(
          onLongPress: () {
            HapticFeedback.heavyImpact();
            onReset();
          },
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          child: Padding(
            padding: EdgeInsets.only(
              left: theme.tokens.spaceExtraLarge,
              top: theme.tokens.spaceExtraLarge,
              right: theme.tokens.spaceExtraLarge,
              bottom: theme.tokens.spaceExtraLarge + bottomInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.tokens.spaceMedium,
              children: [
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    radius: Radius.circular(theme.tokens.radiusSmall),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      dragStartBehavior: DragStartBehavior.down,
                      child: Text(
                        item.textAr,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: theme.tokens.textHeightLoose,
                        ),
                      ),
                    ),
                  ),
                ),
                ItemCountWidget(
                  item: item,
                  currentCount: currentCount,
                  isDone: isDone,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
