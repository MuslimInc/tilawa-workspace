import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Compact text action for feature app bars (My sessions, Wallet, …).
class QuranSessionsAppBarLink extends StatelessWidget {
  const QuranSessionsAppBarLink({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TilawaButton(
      onPressed: onPressed,
      text: label,
    );
  }
}

/// Feature-scoped scaffold for Quran Tutor student and teacher flows.
///
/// Delegates app bar chrome to [TilawaAppBar]. Keep [title] short; put long
/// copy in [QuranSessionsPageHeader] inside [body].
class QuranSessionsScaffold extends StatelessWidget {
  const QuranSessionsScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottomNavigationBar,
    this.actions,
    this.floatingActionButton,
    this.appBarBottom,
    this.leading,
    this.resizeToAvoidBottomInset = true,
  });

  final String title;
  final Widget body;
  final Widget? bottomNavigationBar;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBarBottom;
  final Widget? leading;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: TilawaAppBar(
        title: title,
        leading: leading,
        actions: actions,
        bottom: appBarBottom,
      ),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
