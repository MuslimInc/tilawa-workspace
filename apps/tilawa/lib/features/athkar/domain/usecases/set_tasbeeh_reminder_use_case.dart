import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../entities/tasbeeh_dhikr.dart';
import '../repositories/tasbeeh_repository.dart';

class SetTasbeehReminderParams {
  const SetTasbeehReminderParams({
    required this.dhikrId,
    required this.enabled,
    this.hour,
    this.minute,
  });

  final String dhikrId;
  final bool enabled;
  final int? hour;
  final int? minute;
}

@lazySingleton
class SetTasbeehReminderUseCase
    implements UseCase<TasbeehDhikr, SetTasbeehReminderParams> {
  SetTasbeehReminderUseCase(this._repository);

  final TasbeehRepository _repository;

  @override
  Future<Either<Failure, TasbeehDhikr>> call(SetTasbeehReminderParams params) {
    return _repository.setReminder(
      dhikrId: params.dhikrId,
      enabled: params.enabled,
      hour: params.hour,
      minute: params.minute,
    );
  }
}
