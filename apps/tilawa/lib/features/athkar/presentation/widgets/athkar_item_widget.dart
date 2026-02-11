import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

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
            padding: EdgeInsets.symmetric(
              vertical: 16.h,
              horizontal: 16.w,
            ).copyWith(bottom: 32.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    radius: const Radius.circular(8),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      dragStartBehavior: DragStartBehavior.down,
                      child: Text(
                        item.textAr,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20.sp,
                          height: 2.0,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
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
