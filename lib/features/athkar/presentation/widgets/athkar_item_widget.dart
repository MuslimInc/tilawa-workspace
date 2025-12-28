import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../domain/entities/athkar_item.dart';

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
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22.sp,
                          height: 1.8,
                          color: theme.colorScheme.onSurface,
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

class ItemCountWidget extends StatelessWidget {
  const ItemCountWidget({
    super.key,
    required this.item,
    required this.currentCount,
    required this.isDone,
  });

  final AthkarItem item;
  final int currentCount;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 80.w,
          height: 80.w,
          child: CircularProgressIndicator(
            value: item.count > 0 ? (currentCount / item.count) : 0,
            strokeWidth: 6,
            backgroundColor:
                (isDone ? const Color(0xFF4CAF50) : const Color(0xFF26A69A))
                    .withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              isDone ? const Color(0xFF4CAF50) : const Color(0xFF26A69A),
            ),
            strokeCap: StrokeCap.round,
          ),
        ),
        Container(
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? const Color(0xFF4CAF50) : const Color(0xFF26A69A),
            boxShadow: [
              BoxShadow(
                color:
                    (isDone ? const Color(0xFF4CAF50) : const Color(0xFF26A69A))
                        .withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: isDone
                ? Icon(
                    FluentIcons.checkmark_24_filled,
                    color: Colors.white,
                    size: 48.sp,
                  )
                : Text(
                    '$currentCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 36.sp,
                      height: 1.2,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
