import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/qibla_direction_entity.dart';
import '../../domain/usecases/check_location_service_use_case.dart';
import '../../domain/usecases/get_qibla_direction_use_case.dart';
import '../../domain/usecases/request_location_permission_use_case.dart';

part 'qibla_event.dart';
part 'qibla_state.dart';

/// Event transformer for throttling events
EventTransformer<T> throttle<T>(Duration duration) {
  return (events, mapper) => events.throttle(duration).switchMap(mapper);
}

@injectable
class QiblaBloc extends Bloc<QiblaEvent, QiblaState> {
  QiblaBloc(
    this._getQiblaDirection,
    this._checkLocationService,
    this._requestLocationPermission,
  ) : super(const QiblaState()) {
    on<CheckLocationService>(
      _onCheckLocationService,
      transformer: sequential(),
    );
    on<RequestLocationPermission>(
      _onRequestLocationPermission,
      transformer: sequential(),
    );
    on<StartQiblaStream>(_onStartQiblaStream, transformer: restartable());
    on<UpdateQiblaDirection>(
      _onUpdateQiblaDirection,
      transformer: throttle(const Duration(milliseconds: 100)),
    );
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
      _qiblaSubscription = _getQiblaDirection(const NoParams())
          .throttle(const Duration(milliseconds: 100))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: (sink) => sink.addError(
              'Sensors not responding. If you are on a Simulator, Compass is not supported.',
            ),
          )
          .listen((direction) {
            // Normalize values to 0-360 range for cleaner data and logs
            final normalizedDirection = QiblaDirectionEntity(
              qibla: direction.qibla % 360,
              direction: direction.direction % 360,
              offset: direction.offset % 360,
            );
            add(UpdateQiblaDirection(normalizedDirection));
          }, onError: (e) => add(QiblaErrorOccurred(e.toString())));
    } catch (e) {
      emit(
        state.copyWith(status: QiblaStatus.error, errorMessage: e.toString()),
      );
    }
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
