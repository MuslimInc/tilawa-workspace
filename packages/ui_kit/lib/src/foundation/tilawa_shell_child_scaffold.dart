import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// [Scaffold] for feature screens hosted under [TilawaAdaptiveShell].
///
/// ## Why this exists
///
/// [TilawaAdaptiveShell] owns keyboard resize (`resizeToAvoidBottomInset: true`).
/// Nested Material [Scaffold]s that also resize compete with shell chrome
/// (bottom nav, mini-player slot) and fill layouts, producing white gaps above
/// the IME or zero-height bodies. This wrapper defaults
/// [resizeToAvoidBottomInset] to `false` so future screens inherit the contract.
///
/// ## When to use
///
/// - Routes rendered inside [TilawaAdaptiveShell] / `AppShellScreen`
///
/// ## When not to use
///
/// - Root / outside-shell screens (auth, immersive Athkar, Quran reader,
///   `/player`, standalone package flows) — use Material [Scaffold] with the
///   default `resizeToAvoidBottomInset: true` (or an intentional override).
///
/// Keep bodies scrollable; pair search/form fields with light
/// `scrollPadding` (`keyboardInset` + small buffer), not a second full
/// keyboard pad via [TilawaSafeAreaX.effectiveKeyboardInset].
class TilawaShellChildScaffold extends StatelessWidget {
  /// Creates a shell-hosted feature scaffold.
  const TilawaShellChildScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.persistentFooterAlignment = AlignmentDirectional.centerEnd,
    this.drawer,
    this.onDrawerChanged,
    this.endDrawer,
    this.onEndDrawerChanged,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = false,
    this.primary = true,
    this.drawerDragStartBehavior = DragStartBehavior.start,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.restorationId,
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final List<Widget>? persistentFooterButtons;
  final AlignmentDirectional persistentFooterAlignment;
  final Widget? drawer;
  final DrawerCallback? onDrawerChanged;
  final Widget? endDrawer;
  final DrawerCallback? onEndDrawerChanged;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;

  /// Defaults to `false` so the shell remains the sole IME geometry owner.
  /// Override only with an explicit product reason documented at the call site.
  final bool resizeToAvoidBottomInset;

  final bool primary;
  final DragStartBehavior drawerDragStartBehavior;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Color? drawerScrimColor;
  final double? drawerEdgeDragWidth;
  final bool drawerEnableOpenDragGesture;
  final bool endDrawerEnableOpenDragGesture;
  final String? restorationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      persistentFooterButtons: persistentFooterButtons,
      persistentFooterAlignment: persistentFooterAlignment,
      drawer: drawer,
      onDrawerChanged: onDrawerChanged,
      endDrawer: endDrawer,
      onEndDrawerChanged: onEndDrawerChanged,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      primary: primary,
      drawerDragStartBehavior: drawerDragStartBehavior,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawerScrimColor: drawerScrimColor,
      drawerEdgeDragWidth: drawerEdgeDragWidth,
      drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
      restorationId: restorationId,
    );
  }
}
