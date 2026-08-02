import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/athkar_item.dart';
import '../cubit/athkar_cubit.dart';
import 'athkar_item_widget.dart';

class AthkarDetailsBody extends StatefulWidget {
  const AthkarDetailsBody({
    super.key,
    required this.items,
    required this.currentCounts,
    required this.pageController,
    required this.onPageChanged,
  });

  final List<AthkarItem> items;
  final Map<int, int> currentCounts;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  @override
  State<AthkarDetailsBody> createState() => _AthkarDetailsBodyState();
}

class _AthkarDetailsBodyState extends State<AthkarDetailsBody> {
  bool _isAnimating = false;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: _isAnimating,
      child: PageView.builder(
        controller: widget.pageController,
        physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
        dragStartBehavior: DragStartBehavior.down,
        onPageChanged: widget.onPageChanged,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final AthkarItem item = widget.items[index];
          final int currentCount = widget.currentCounts[item.id] ?? 0;
          return SafeArea(
            top: false,
            bottom: false,
            child: AthkarItemWidget(
              item: item,
              onTap: () => _onItemTap(context, item, index, currentCount),
            ),
          );
        },
      ),
    );
  }

  void _onItemTap(
    BuildContext context,
    AthkarItem item,
    int index,
    int currentCount,
  ) {
    if (currentCount > 0) {
      context.read<AthkarCubit>().decrementCount(item.id);
    }

    if (currentCount <= 1) {
      _advanceAfterComplete(index);
    }
  }

  void _advanceAfterComplete(int index) {
    if (!widget.pageController.hasClients || index >= widget.items.length - 1) {
      return;
    }
    setState(() {
      _isAnimating = true;
    });
    widget.pageController
        .animateToPage(
          index + 1,
          duration: context.tokens.durationFast,
          curve: Curves.easeInOut,
        )
        .whenComplete(() {
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        });
  }

  @override
  void didUpdateWidget(AthkarDetailsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isAnimating || !widget.pageController.hasClients) {
      return;
    }

    final int currentPage = widget.pageController.page?.round() ?? 0;
    if (currentPage >= widget.items.length) {
      return;
    }

    final AthkarItem item = widget.items[currentPage];
    final int currentCount = widget.currentCounts[item.id] ?? 0;
    final int oldCount = oldWidget.currentCounts[item.id] ?? 0;

    if (currentCount == 0 &&
        oldCount > 0 &&
        currentPage < widget.items.length - 1) {
      setState(() {
        _isAnimating = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && widget.pageController.hasClients) {
          widget.pageController
              .animateToPage(
                currentPage + 1,
                duration: context.tokens.durationFast,
                curve: Curves.easeInOut,
              )
              .whenComplete(() {
                if (mounted) {
                  setState(() {
                    _isAnimating = false;
                  });
                }
              });
        } else if (mounted) {
          setState(() {
            _isAnimating = false;
          });
        }
      });
    }
  }
}
