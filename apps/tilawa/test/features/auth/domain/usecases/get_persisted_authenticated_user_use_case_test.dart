import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/domain/usecases/get_persisted_authenticated_user_use_case.dart';

void main() {
  test('always returns null because AuthBloc no longer hydrates', () async {
    final GetPersistedAuthenticatedUserUseCase useCase =
        GetPersistedAuthenticatedUserUseCase();

    expect(await useCase(), isNull);
  });
}
