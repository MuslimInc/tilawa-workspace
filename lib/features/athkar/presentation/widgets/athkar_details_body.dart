import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/athkar_item.dart';
import '../cubit/athkar_cubit.dart';
import 'athkar_item_widget.dart';

class AthkarDetailsBody extends StatefulWidget {
  const AthkarDetailsBody({
    super.key,
    required this.items,
    required this.currentCounts,
    required this.onPageChanged,
  });

  final List<AthkarItem> items;
  final Map<int, int> currentCounts;
  final ValueChanged<int> onPageChanged;

  @override
  State<AthkarDetailsBody> createState() => _AthkarDetailsBodyState();
}

class _AthkarDetailsBodyState extends State<AthkarDetailsBody> {
  late PageController _pageController;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: _isAnimating,
      child: PageView.builder(
        controller: _pageController,
        physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
        dragStartBehavior: DragStartBehavior.down,
        onPageChanged: widget.onPageChanged,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final AthkarItem item = widget.items[index];
          final int currentCount = widget.currentCounts[item.id] ?? 0;
          return AthkarItemWidget(
            item: item,
            currentCount: currentCount,
            onTap: () => _onItemTap(context, item, index, currentCount),
            onReset: () {
              context.read<AthkarCubit>().resetCount(item.id);
            },
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
      if (_pageController.hasClients && index < widget.items.length - 1) {
        setState(() {
          _isAnimating = true;
        });
        _pageController
            .animateToPage(
              index + 1,
              duration: const Duration(milliseconds: 300),
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
    }
  }

  @override
  void didUpdateWidget(AthkarDetailsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isAnimating || !_pageController.hasClients) {
      return;
    }

    final int currentPage = _pageController.page?.round() ?? 0;
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
        if (mounted && _pageController.hasClients) {
          _pageController
              .animateToPage(
                currentPage + 1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              )
              .whenComplete(() {
                if (mounted) {
                  setState(() {
                    _isAnimating = false;
                  });
                }
              });
        } else {
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        }
      });
    }
  }
}
