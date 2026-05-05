import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:qibla/qibla.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';
import 'package:vibration/vibration.dart';

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
  int _eventCounter = 0;
  bool _wasAlignedWithQibla = false;

  /// Checks location service, permission, and starts the Qibla
  /// stream in a single pass — avoiding multiple event dispatches.
  Future<void> _onCheckLocationService(
    CheckLocationService event,
    Emitter<QiblaState> emit,
  ) async {
    // Skip re-initialization if the stream is already active.
    if (state.status == QiblaStatus.success && _qiblaSubscription != null) {
      return;
    }

    emit(state.copyWith(status: QiblaStatus.loading, errorMessage: null));

    // 1. Check if Location Services are enabled.
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
        if (isClosed) return;
        if (!isServiceEnabled) {
          emit(state.copyWith(status: QiblaStatus.serviceDisabled));
          return;
        }

        // 2. Check / request location permission inline.
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
            if (isClosed) return;
            if (!isGranted) {
              emit(state.copyWith(status: QiblaStatus.permissionDenied));
              return;
            }

            // 3. Permission granted — start the stream immediately.
            _startListening();
          },
        );
      },
    );
  }

  /// Handles the retry button for requesting location permission.
  Future<void> _onRequestLocationPermission(
    RequestLocationPermission event,
    Emitter<QiblaState> emit,
  ) async {
    emit(state.copyWith(status: QiblaStatus.loading, errorMessage: null));

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
        if (isClosed) return;
        if (isGranted) {
          _startListening();
        } else {
          emit(state.copyWith(status: QiblaStatus.permissionDenied));
        }
      },
    );
  }

  /// Handles the explicit start-stream event (e.g. from a retry).
  Future<void> _onStartQiblaStream(
    StartQiblaStream event,
    Emitter<QiblaState> emit,
  ) async {
    emit(state.copyWith(status: QiblaStatus.loading, errorMessage: null));
    _startListening();
  }

  /// Subscribes to the Qibla direction stream.
  void _startListening() {
    if (kDebugMode) {
      debugPrint('[CompassSensor] QiblaBloc._startListening begin');
    }
    _wasAlignedWithQibla = false;
    _qiblaSubscription?.cancel();
    try {
      _qiblaSubscription = _getQiblaDirection(const NoParams()).listen(
        (direction) {
          _eventCounter++;
          if (kDebugMode && (_eventCounter <= 5 || _eventCounter % 20 == 0)) {
            debugPrint(
              '[CompassSensor] stream event #$_eventCounter '
              'heading=${_formatAngle(direction.direction)} '
              'qibla=${_formatAngle(direction.qibla)} '
              'offset=${_formatAngle(direction.offset)}',
            );
          }
          add(UpdateQiblaDirection(direction));
        },
        onError: (error) {
          if (kDebugMode) {
            debugPrint('[CompassSensor] stream error: $error');
          }
          add(QiblaErrorOccurred(error.toString()));
        },
        onDone: () {
          if (kDebugMode) {
            debugPrint('[CompassSensor] stream done');
          }
        },
        cancelOnError: false,
      );
      if (kDebugMode) {
        debugPrint('[CompassSensor] QiblaBloc._startListening subscribed');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[CompassSensor] QiblaBloc._startListening catch: $error');
      }
      add(QiblaErrorOccurred(error.toString()));
    }
  }

  Future<void> _onStopQiblaStream(
    StopQiblaStream event,
    Emitter<QiblaState> emit,
  ) async {
    if (kDebugMode) {
      debugPrint('[CompassSensor] StopQiblaStream received');
    }
    await _qiblaSubscription?.cancel();
    _qiblaSubscription = null;
    _wasAlignedWithQibla = false;
    Qibla.instance.dispose();
    if (kDebugMode) {
      debugPrint('[CompassSensor] subscription canceled + Qibla.dispose()');
    }
  }

  void _onUpdateQiblaDirection(
    UpdateQiblaDirection event,
    Emitter<QiblaState> emit,
  ) {
    final bool isAlignedWithQibla = event.direction.isAligned;
    if (isAlignedWithQibla && !_wasAlignedWithQibla) {
      unawaited(_triggerQiblaAlignmentVibration());
    }
    _wasAlignedWithQibla = isAlignedWithQibla;

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
  Future<void> close() async {
    if (kDebugMode) {
      debugPrint('[CompassSensor] QiblaBloc.close');
    }
    await _qiblaSubscription?.cancel();
    _qiblaSubscription = null;
    _wasAlignedWithQibla = false;
    Qibla.instance.dispose();
    if (kDebugMode) {
      debugPrint('[CompassSensor] QiblaBloc.close canceled + disposed');
    }
    return super.close();
  }

  String _formatAngle(double value) {
    final double normalized = (value % 360 + 360) % 360;
    final int roundedTenths = (normalized * 10).round() % 3600;
    return (roundedTenths / 10).toStringAsFixed(1);
  }

  Future<void> _triggerQiblaAlignmentVibration() async {
    try {
      final bool hasVibrator = await Vibration.hasVibrator();
      if (!hasVibrator) {
        return;
      }

      final bool hasAmplitude = await Vibration.hasAmplitudeControl();
      await Vibration.vibrate(
        duration: 180,
        amplitude: hasAmplitude ? 160 : -1,
      );
    } catch (_) {
      // Devices without vibration support, platform failures, and simulator
      // gaps should never affect Qibla state updates.
    }
  }
}
