import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../../domain/entities/qibla_direction_entity.dart';
import '../../domain/usecases/check_location_service_use_case.dart';
import '../../domain/usecases/get_qibla_direction_use_case.dart';
import '../../domain/usecases/request_location_permission_use_case.dart';

part 'qibla_event.dart';
part 'qibla_state.dart';

@injectable
class QiblaBloc extends Bloc<QiblaEvent, QiblaState> {
  QiblaBloc(
    this._getQiblaDirection,
    this._checkLocationService,
    this._requestLocationPermission,
  ) : super(const QiblaState()) {
    on<CheckLocationService>(_onCheckLocationService);
    on<RequestLocationPermission>(_onRequestLocationPermission);
    on<StartQiblaStream>(_onStartQiblaStream);
    on<StopQiblaStream>(_onStopQiblaStream);
    on<UpdateQiblaDirection>(_onUpdateQiblaDirection);
    on<QiblaErrorOccurred>(_onQiblaErrorOccurred);
  }

  final GetQiblaDirectionUseCase _getQiblaDirection;
  final CheckLocationServiceUseCase _checkLocationService;
  final RequestLocationPermissionUseCase _requestLocationPermission;

  StreamSubscription<QiblaDirectionEntity>? _qiblaSubscription;

  /// First check: Is Location Service Enabled (GPS On)?
  Future<void> _onCheckLocationService(
    CheckLocationService event,
    Emitter<QiblaState> emit,
  ) async {
    emit(state.copyWith(status: QiblaStatus.loading));

    // 1. Check if Location Services are enabled
    final Either<Failure, bool> serviceResult = await _checkLocationService(
      const NoParams(),
    );

    await serviceResult.fold(
      (failure) async => emit(
        state.copyWith(
          status: QiblaStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (isServiceEnabled) async {
        if (isClosed) {
          return;
        }
        if (isServiceEnabled) {
          // 2. If Service is Enabled, we MUST Check/Request Permissions
          // We trigger the RequestLocationPermission event which handles the permission check logic
          add(const RequestLocationPermission());
        } else {
          emit(state.copyWith(status: QiblaStatus.serviceDisabled));
        }
      },
    );
  }

  /// Second check: Are Location Permissions Granted?
  Future<void> _onRequestLocationPermission(
    RequestLocationPermission event,
    Emitter<QiblaState> emit,
  ) async {
    // 3. This UseCase checks permission status and requests it if denied.
    final Either<Failure, bool> permissionResult =
        await _requestLocationPermission(const NoParams());

    await permissionResult.fold(
      (failure) async => emit(
        state.copyWith(
          status: QiblaStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (isGranted) async {
        if (isGranted) {
          // 4. Permission Granted -> Start Stream
          add(const StartQiblaStream());
        } else {
          emit(state.copyWith(status: QiblaStatus.permissionDenied));
        }
      },
    );
  }

  Future<void> _onStartQiblaStream(
    StartQiblaStream event,
    Emitter<QiblaState> emit,
  ) async {
    try {
      emit(state.copyWith(status: QiblaStatus.loading));

      await _qiblaSubscription?.cancel();
      _qiblaSubscription = _getQiblaDirection(const NoParams()).listen(
        (direction) => add(UpdateQiblaDirection(direction)),
        onError: (error) {
          add(QiblaErrorOccurred(error.toString()));
        },
      );
    } catch (e) {
      emit(
        state.copyWith(status: QiblaStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onStopQiblaStream(
    StopQiblaStream event,
    Emitter<QiblaState> emit,
  ) async {
    await _qiblaSubscription?.cancel();
    _qiblaSubscription = null;
  }

  void _onUpdateQiblaDirection(
    UpdateQiblaDirection event,
    Emitter<QiblaState> emit,
  ) {
    emit(
      state.copyWith(status: QiblaStatus.success, direction: event.direction),
    );
  }

  void _onQiblaErrorOccurred(
    QiblaErrorOccurred event,
    Emitter<QiblaState> emit,
  ) {
    emit(
      state.copyWith(
        status: QiblaStatus.error,
        errorMessage: event.errorMessage,
      ),
    );
  }

  @override
  Future<void> close() {
    _qiblaSubscription?.cancel();
    return super.close();
  }
}
