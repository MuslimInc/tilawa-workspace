import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastUtils {
  const ToastUtils._();

  static void showToast({
    required String msg,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Color? backgroundColor,
    Color? textColor,
  }) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 16.0,
    );
  }

  static void showErrorToast(String msg) {
    showToast(msg: msg, backgroundColor: Colors.red, textColor: Colors.white);
  }

  static void showSuccessToast(String msg) {
    showToast(msg: msg, backgroundColor: Colors.green, textColor: Colors.white);
  }
}
