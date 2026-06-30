import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/quran_sessions/presentation/widgets/debug_livekit_call_tile.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late _MockAuthBloc authBloc;

  setUp(() {
    authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenReturn(
      AuthState.authenticated(
        user: UserEntity(
          id: 'user_1',
          email: 'qa@example.com',
          displayName: 'QA User',
          createdAt: DateTime.utc(2024, 1, 1),
        ),
      ),
    );
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  group('DebugLiveKitCallTile', () {
    testWidgets('hidden when debug gate is off', (tester) async {
      await tester.pumpWidget(
        _wrap(
          authBloc: authBloc,
          child: DebugLiveKitCallTile(
            visibilityGate: () => false,
            liveKitEnabled: true,
          ),
        ),
      );

      expect(find.text('Test LiveKit video call'), findsNothing);
    });

    testWidgets('visible when debug gate on and LiveKit enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          authBloc: authBloc,
          child: DebugLiveKitCallTile(
            visibilityGate: () => true,
            liveKitEnabled: true,
          ),
        ),
      );

      expect(find.text('Test LiveKit video call'), findsOneWidget);
    });

    testWidgets('hidden when LiveKit disabled', (tester) async {
      await tester.pumpWidget(
        _wrap(
          authBloc: authBloc,
          child: DebugLiveKitCallTile(
            visibilityGate: () => true,
            liveKitEnabled: false,
          ),
        ),
      );

      expect(find.text('Test LiveKit video call'), findsNothing);
    });
  });
}

Widget _wrap({required _MockAuthBloc authBloc, required Widget child}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    home: BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: Scaffold(body: child),
    ),
  );
}
