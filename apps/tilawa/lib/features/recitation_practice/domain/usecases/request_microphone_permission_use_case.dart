import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../data/services/microphone_permission_service.dart';

@lazySingleton
class RequestMicrophonePermissionUseCase {
  const RequestMicrophonePermissionUseCase(this._permissionService);

  final MicrophonePermissionService _permissionService;

  Future<Either<Failure, bool>> call() async {
    try {
      final bool granted = await _permissionService.requestPermission();
      if (granted) {
        return const Right(true);
      }
      return Left(
        Failure.permissionDenied('Microphone permission is required.'),
      );
    } catch (error) {
      return Left(Failure.unexpectedError(error.toString()));
    }
  }
}
