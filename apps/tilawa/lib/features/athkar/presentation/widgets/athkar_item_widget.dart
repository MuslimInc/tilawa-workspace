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
    final double bottomInset = context.systemBottomSafeArea;

    final isDone = currentCount == 0;
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

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
            padding: EdgeInsets.fromLTRB(
              tokens.spaceLarge,
              tokens.spaceLarge,
              tokens.spaceLarge,
              bottomInset,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: tokens.contentMaxWidthReader,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: tokens.spaceLarge,
                  children: [
                    Expanded(
                      child: TilawaCard(
                        borderRadius: tokens.radiusExtraLarge,
                        surface: TilawaCardSurface.raised,
                        backgroundColor: colorScheme.surface,
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.spaceExtraLarge,
                          vertical: tokens.spaceExtraLarge,
                        ),
                        child: Scrollbar(
                          controller: _scrollController,
                          radius: Radius.circular(tokens.radiusSmall),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            dragStartBehavior: DragStartBehavior.down,
                            child: Text(
                              item.textAr,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                height: tokens.textHeightLoose,
                                fontWeight: FontWeight.w600,
                              ),
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
        ),
      ),
    );
  }
}
