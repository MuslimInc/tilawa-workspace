import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mockito/annotations.dart';
import 'package:tilawa/core/services/device_token_service.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/repositories/user_repository.dart';

@GenerateMocks([
  UserRepository,
  DeviceTokenService,
  FirebaseMessaging,
  AuthRepository,
])
void main() {}
