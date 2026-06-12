import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';

void main() {
  final UserEntity user = UserEntity(
    id: '123',
    email: 'test@example.com',
    displayName: 'Test User',
    photoUrl: 'http://example.com/photo.jpg',
    createdAt: DateTime.utc(2026, 6, 12),
  );

  group('UserEntity JSON', () {
    test('round-trips through toJson/fromJson', () {
      final UserEntity decoded = UserEntity.fromJson(user.toJson());

      expect(decoded, user);
    });

    test('fromJson handles null photoUrl', () {
      final UserEntity withoutPhoto = user.copyWith(photoUrl: null);

      final UserEntity decoded = UserEntity.fromJson(withoutPhoto.toJson());

      expect(decoded.photoUrl, isNull);
      expect(decoded, withoutPhoto);
    });
  });

  group('AuthResult JSON', () {
    test('success round-trips', () {
      final AuthResult result = AuthResult.success(user: user);

      expect(AuthResult.fromJson(result.toJson()), result);
    });

    test('failure round-trips with code and details', () {
      const AuthResult result = AuthResult.failure(
        message: 'boom',
        code: 'sign-in-init-failed',
        details: 'stack',
      );

      expect(AuthResult.fromJson(result.toJson()), result);
    });

    test('cancelled round-trips', () {
      const AuthResult result = AuthResult.cancelled();

      expect(AuthResult.fromJson(result.toJson()), result);
    });
  });
}
