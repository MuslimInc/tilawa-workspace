import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/errors/failures.dart';

void main() {
  late AppLocalizations ar;
  late AppLocalizations en;

  setUpAll(() {
    ar = lookupAppLocalizations(const Locale('ar'));
    en = lookupAppLocalizations(const Locale('en'));
  });

  group('PurchaseFailure.verificationFailed localizedMessage', () {
    testWidgets('returns Arabic copy when app locale is ar', (tester) async {
      String? message;
      await tester.pumpWidget(
        _localizedHarness(
          locale: const Locale('ar'),
          builder: (BuildContext context) {
            message = const PurchaseFailure.verificationFailed()
                .localizedMessage(context);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(message, ar.purchaseVerificationFailed);
      expect(message, isNot(en.purchaseVerificationFailed));
    });

    testWidgets('returns English copy when app locale is en', (tester) async {
      String? message;
      await tester.pumpWidget(
        _localizedHarness(
          locale: const Locale('en'),
          builder: (BuildContext context) {
            message = const PurchaseFailure.verificationFailed()
                .localizedMessage(context);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(message, en.purchaseVerificationFailed);
      expect(message, isNot(ar.purchaseVerificationFailed));
    });

    testWidgets(
      'ignores English Firebase message on failure.message when locale is ar',
      (tester) async {
        const String firebaseEnglish =
            'We could not confirm your support. Please try again.';
        String? message;
        await tester.pumpWidget(
          _localizedHarness(
            locale: const Locale('ar'),
            builder: (BuildContext context) {
              message = const PurchaseFailure(
                firebaseEnglish,
                PurchaseFailureReason.verificationFailed,
              ).localizedMessage(context);
              return const SizedBox.shrink();
            },
          ),
        );

        expect(message, ar.purchaseVerificationFailed);
        expect(message, isNot(firebaseEnglish));
      },
    );

    testWidgets(
      'context.l10n matches lookupAppLocalizations for purchase errors',
      (tester) async {
        await tester.pumpWidget(
          _localizedHarness(
            locale: const Locale('ar'),
            builder: (BuildContext context) {
              expect(
                context.l10n.purchaseVerificationFailed,
                lookupAppLocalizations(
                  const Locale('ar'),
                ).purchaseVerificationFailed,
              );
              expect(
                context.l10n.purchaseVerificationFailed,
                isNot(en.purchaseVerificationFailed),
              );
              expect(Localizations.localeOf(context).languageCode, 'ar');
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  });
}

Widget _localizedHarness({
  required Locale locale,
  required WidgetBuilder builder,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Builder(builder: builder),
  );
}
