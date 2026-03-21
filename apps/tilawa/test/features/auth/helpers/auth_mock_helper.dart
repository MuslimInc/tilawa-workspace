import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/services/device_token_service.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/repositories/user_repository.dart';
import 'package:tilawa/features/auth/domain/usecases/sync_device_token_use_case.dart';
import 'package:tilawa/features/premium/data/datasources/premium_local_datasource.dart';

@GenerateMocks([
  UserRepository,
  DeviceTokenService,
  FirebaseMessaging,
  AuthRepository,
  SharedPreferencesAsync,
  SyncDeviceTokenUseCase,
  PremiumLocalDataSource,
])
void main() {}
