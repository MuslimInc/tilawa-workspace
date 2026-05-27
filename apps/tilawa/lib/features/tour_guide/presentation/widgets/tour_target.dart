import 'package:flutter/material.dart';
import 'package:tilawa/core/di/injection.dart';

import '../../domain/services/tour_target_registry.dart';

/// Wraps [child] and registers a stable [targetId] for tour highlighting.
///
/// ```dart
/// TourTarget(
///   targetId: ReciterTourTargets.searchField,
///   child: TilawaSearchField(...),
/// )
/// ```
class TourTarget extends StatefulWidget {
  const TourTarget({
    super.key,
    required this.targetId,
    required this.child,
  });

  final String targetId;
  final Widget child;

  @override
  State<TourTarget> createState() => _TourTargetState();
}

class _TourTargetState extends State<TourTarget> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    getIt<TourTargetRegistry>().register(widget.targetId, _key);
  }

  @override
  void didUpdateWidget(covariant TourTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetId != widget.targetId) {
      getIt<TourTargetRegistry>().unregister(oldWidget.targetId, _key);
      getIt<TourTargetRegistry>().register(widget.targetId, _key);
    }
  }

  @override
  void dispose() {
    getIt<TourTargetRegistry>().unregister(widget.targetId, _key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
