import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class ToastUtils {
  const ToastUtils._();

  static void showToast({
    required String msg,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Color? backgroundColor,
    Color? textColor,
  }) {
    // Fire and forget, but catch errors to avoid crashes/test failures from missing plugins
    // No fixed fontSize: the platform default tracks the system text scale.
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      backgroundColor: backgroundColor,
      textColor: textColor,
    ).catchError((_) {
      // Ignore errors (e.g. MissingPluginException in tests)
      return null;
    });
  }

  static void showErrorToast(String msg) {
    // Semantic tokens, not Material's raw red/green — toasts render in the OS
    // layer and can't read the theme, so they lock to the brand semantics.
    showToast(
      msg: msg,
      backgroundColor: AppColors.error,
      textColor: Colors.white,
    );
  }

  static void showSuccessToast(String msg) {
    showToast(
      msg: msg,
      backgroundColor: AppColors.success,
      textColor: Colors.white,
    );
  }
}
