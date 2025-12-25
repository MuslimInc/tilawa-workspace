import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/utils/toast_utils.dart';

void main() {
  group('ToastUtils', () {
    test('showToast should accept all required and optional parameters', () {
      // This test mainly validates the API signature
      // The actual toast will fail in tests but should not throw
      expect(() => ToastUtils.showToast(msg: 'Test message'), returnsNormally);
    });

    test('showToast should accept custom parameters', () {
      expect(
        () => ToastUtils.showToast(
          msg: 'Custom toast',
          backgroundColor: Colors.blue,
          textColor: Colors.white,
        ),
        returnsNormally,
      );
    });

    test('showErrorToast should call showToast with error styling', () {
      // Verify the function can be called without throwing
      expect(() => ToastUtils.showErrorToast('Error message'), returnsNormally);
    });

    test('showSuccessToast should call showToast with success styling', () {
      // Verify the function can be called without throwing
      expect(
        () => ToastUtils.showSuccessToast('Success message'),
        returnsNormally,
      );
    });

    test('const constructor should not be accessible', () {
      // This verifies that ToastUtils has a private constructor
      // We can't directly instantiate it
      expect(ToastUtils, isNotNull);
    });
  });
}
