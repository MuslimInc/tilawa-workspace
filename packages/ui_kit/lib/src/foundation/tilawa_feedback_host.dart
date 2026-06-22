import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../molecules/tilawa_feedback_strip.dart';
import 'design_tokens.dart';
import 'tilawa_comfortable_reach_padding.dart';
import 'tilawa_feedback_action.dart';
import 'tilawa_feedback_insets.dart';
import 'tilawa_interaction_feedback.dart';
import 'tilawa_toast.dart';

/// Default visible lifetime for a toast before auto-dismiss.
const Duration kTilawaToastDuration = Duration(seconds: 3);

/// Default undo / actionable toast lifetime before auto-dismiss.
const Duration kTilawaUndoToastDuration = Duration(seconds: 4);

@immutable
class _TilawaToastRequest {
  const _TilawaToastRequest({
    required this.message,
    required this.variant,
    required this.duration,
    required this.bottomObstruction,
    this.actions = const <TilawaFeedbackAction>[],
    this.dedupeKey,
  });

  final String message;
  final TilawaFeedbackVariant variant;
  final Duration? duration;
  final double bottomObstruction;
  final List<TilawaFeedbackAction> actions;
  final String? dedupeKey;

  bool get isPersistent => duration == null;

  String get identity => dedupeKey ?? message;
}

/// Host state surfaced to [TilawaFeedback.showToast].
abstract class TilawaFeedbackController {
  /// Enqueues a transient toast.
  void showToast({
    required BuildContext context,
    required String message,
    required TilawaFeedbackVariant variant,
    Duration duration = kTilawaToastDuration,
    String? dedupeKey,
  });

  /// Enqueues a toast with optional trailing actions.
  ///
  /// Pass [duration] as `null` to keep the toast visible until an action fires.
  void showActionable({
    required BuildContext context,
    required String message,
    required TilawaFeedbackVariant variant,
    Duration? duration = kTilawaUndoToastDuration,
    required List<TilawaFeedbackAction> actions,
    String? dedupeKey,
  });
}

/// Inherited lookup for [TilawaFeedbackController].
class TilawaFeedbackScope extends InheritedWidget {
  /// Creates a feedback scope.
  const TilawaFeedbackScope({
    super.key,
    required this.controller,
    required super.child,
  });

  /// Active feedback host.
  final TilawaFeedbackController controller;

  /// Returns the nearest [TilawaFeedbackController].
  static TilawaFeedbackController of(BuildContext context) {
    final TilawaFeedbackScope? scope = context
        .dependOnInheritedWidgetOfExactType<TilawaFeedbackScope>();
    assert(
      scope != null,
      'TilawaFeedbackScope not found. Wrap MaterialApp in TilawaFeedbackHost.',
    );
    return scope!.controller;
  }

  /// Returns the nearest controller when present.
  static TilawaFeedbackController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TilawaFeedbackScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(TilawaFeedbackScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Root overlay host for transient Tilawa feedback.
///
/// Place in [MaterialApp.builder] so toasts render above all routes.
class TilawaFeedbackHost extends StatefulWidget {
  /// Creates the app-wide feedback host.
  const TilawaFeedbackHost({super.key, required this.child});

  /// Routed app content.
  final Widget child;

  @override
  State<TilawaFeedbackHost> createState() => _TilawaFeedbackHostState();
}

class _TilawaFeedbackHostState extends State<TilawaFeedbackHost>
    with SingleTickerProviderStateMixin
    implements TilawaFeedbackController {
  final List<_TilawaToastRequest> _queue = <_TilawaToastRequest>[];
  _TilawaToastRequest? _active;
  Timer? _dismissTimer;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(_fadeAnimation);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void showToast({
    required BuildContext context,
    required String message,
    required TilawaFeedbackVariant variant,
    Duration duration = kTilawaToastDuration,
    String? dedupeKey,
  }) {
    _enqueue(
      _TilawaToastRequest(
        message: message,
        variant: variant,
        duration: duration,
        bottomObstruction: TilawaFeedbackInsets.maybeBottomObstruction(
          context,
        ),
        dedupeKey: dedupeKey ?? message,
      ),
    );
  }

  @override
  void showActionable({
    required BuildContext context,
    required String message,
    required TilawaFeedbackVariant variant,
    Duration? duration = kTilawaUndoToastDuration,
    required List<TilawaFeedbackAction> actions,
    String? dedupeKey,
  }) {
    _enqueue(
      _TilawaToastRequest(
        message: message,
        variant: variant,
        duration: duration,
        bottomObstruction: TilawaFeedbackInsets.maybeBottomObstruction(
          context,
        ),
        actions: actions,
        dedupeKey: dedupeKey,
      ),
    );
  }

  void _enqueue(_TilawaToastRequest request) {
    final String? dedupeKey = request.dedupeKey;
    if (dedupeKey != null) {
      if (_active?.dedupeKey == dedupeKey) {
        if (request.actions.isNotEmpty) {
          unawaited(_replaceActive(request));
        }
        return;
      }
      if (_queue.any((_TilawaToastRequest r) => r.dedupeKey == dedupeKey)) {
        return;
      }
    }

    if (_active == null) {
      unawaited(_present(request));
      return;
    }

    _queue.add(request);
  }

  Future<void> _replaceActive(_TilawaToastRequest request) async {
    _dismissTimer?.cancel();
    await _animationController.reverse(from: 1);
    if (!mounted) {
      return;
    }
    setState(() => _active = null);
    await _present(request);
  }

  Future<void> _present(_TilawaToastRequest request) async {
    _dismissTimer?.cancel();
    setState(() => _active = request);

    if (request.variant == TilawaFeedbackVariant.error) {
      TilawaInteractionFeedback.trigger(TilawaHaptic.lightImpact);
    }

    final TilawaDesignTokens tokens = Theme.of(context).tokens;
    _animationController.duration = tokens.durationFast;
    await _animationController.forward(from: 0);

    if (!mounted || _active != request) {
      return;
    }

    SemanticsService.sendAnnouncement(
      View.of(context),
      request.message,
      Directionality.of(context),
    );

    final Duration? duration = request.duration;
    if (duration != null) {
      _dismissTimer = Timer(duration, () {
        unawaited(_dismissActive());
      });
    }
  }

  void _onActionPressed(TilawaFeedbackAction action) {
    action.onPressed();
    unawaited(_dismissActive());
  }

  Future<void> _dismissActive() async {
    if (_active == null || !mounted) {
      return;
    }

    final TilawaDesignTokens tokens = Theme.of(context).tokens;
    _animationController.duration = tokens.durationFast;
    await _animationController.reverse(from: 1);

    if (!mounted) {
      return;
    }

    setState(() => _active = null);

    if (_queue.isEmpty) {
      return;
    }

    final _TilawaToastRequest next = _queue.removeAt(0);
    await _present(next);
  }

  double _resolveBottomInset(BuildContext context, double obstruction) {
    return TilawaComfortableReachPadding.resolve(
          context,
          kind: TilawaComfortableReachKind.floating,
          keyboardAware: true,
        ) +
        obstruction;
  }

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;
    final _TilawaToastRequest? active = _active;
    final double side = tokens.spaceLarge;

    return TilawaFeedbackScope(
      controller: this,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          widget.child,
          if (active != null)
            Positioned(
              left: side,
              right: side,
              bottom: _resolveBottomInset(
                context,
                active.bottomObstruction,
              ),
              child: SafeArea(
                top: false,
                left: false,
                right: false,
                bottom: false,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: TilawaToast(
                      key: ValueKey<String>(active.identity),
                      variant: active.variant,
                      message: active.message,
                      actions: active.actions,
                      onActionPressed: _onActionPressed,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
