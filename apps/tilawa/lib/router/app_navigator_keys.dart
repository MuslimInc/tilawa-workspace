import 'package:flutter/material.dart';

/// Root [NavigatorState] for [GoRouter] and full-screen routes that must cover
/// [AppShellScreen] chrome (e.g. side nav on tablets).
final GlobalKey<NavigatorState> appRootNavigatorKey =
    GlobalKey<NavigatorState>();
