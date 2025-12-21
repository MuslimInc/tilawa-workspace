import 'package:injectable/injectable.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/usecases/get_current_user_use_case.dart';

enum SplashDestination { home, login }

@injectable
class GetSplashNextRouteUseCase {
  GetSplashNextRouteUseCase(this._getCurrentUserUseCase);

  final GetCurrentUserUseCase _getCurrentUserUseCase;

  Future<SplashDestination> call() async {
    // Check user for future logic (e.g. specialized greeting or analytics)
    final UserEntity? user = _getCurrentUserUseCase();

    if (user != null) {
      // User is logged in
    }

    return SplashDestination.home;
  }
}
