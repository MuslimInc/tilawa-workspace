import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_feedback_action.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_toast.dart';
import 'package:tilawa_ui_kit/src/molecules/tilawa_feedback_strip.dart';

import '../../lib/src/previews/preview_wrapper.dart';

/// Snapshot width for floating toast goldens (typical phone content width).
const double kGoldenToastWidth = 360;

/// Long English copy for overflow / wrapping regression.
const String kGoldenToastLongEnglishMessage =
    'Your weekly availability schedule was saved successfully and students '
    'can now book the open slots you published.';

/// Long Arabic copy for RTL wrapping regression.
const String kGoldenToastLongArabicMessage =
    'تم حفظ جدول التوفر الأسبوعي بنجاح ويمكن للطلاب الآن حجز المواعيد '
    'المفتوحة التي قمت بنشرها على لوحة المعلم.';

/// Wraps a [TilawaToast] in the standard golden preview environment.
Widget goldenToastPreview({
  required Widget child,
  bool isDark = false,
  bool isRTL = false,
  double textScale = 1.0,
  double width = kGoldenToastWidth,
}) {
  return TilawaPreviewWrapper(
    isDark: isDark,
    isRTL: isRTL,
    textScale: textScale,
    child: SizedBox(width: width, child: child),
  );
}

/// Builds a [TilawaToast] with a no-op action handler for static goldens.
TilawaToast goldenToast({
  required TilawaFeedbackVariant variant,
  required String message,
  List<TilawaFeedbackAction> actions = const <TilawaFeedbackAction>[],
}) {
  return TilawaToast(
    variant: variant,
    message: message,
    actions: actions,
    onActionPressed: (_) {},
  );
}

/// Strip-only fixture when the leading slot uses a spinner instead of an icon.
Widget goldenToastSpinnerStrip({
  required String message,
  required Color backgroundColor,
  required Color foregroundColor,
}) {
  return TilawaFeedbackStrip(
    icon: Icons.info_outline,
    message: message,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    showSpinner: true,
    variant: TilawaFeedbackVariant.info,
    messageMaxLines: 2,
    reserveMessageLines: true,
  );
}
