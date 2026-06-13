import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'test_download_bloc_types.dart';

/// Bloc WITH the isClosed check - this will NOT crash
class BlocWithFix extends Bloc<TestDownloadEvent, TestDownloadState> {
  BlocWithFix({required this._progressStream}) : super(TestInitial()) {
    on<TestInitialize>((event, emit) async {
      emit(TestDownloading(0.0));
      _subscription = _progressStream.listen((progress) {
        if (isClosed) return;
        add(TestProgressUpdated(progress));
      });
    });

    on<TestProgressUpdated>((event, emit) async {
      emit(TestDownloading(event.progress));
    });
  }

  final Stream<double> _progressStream;
  // ignore: unused_field
  StreamSubscription<double>? _subscription;

  @override
  Future<void> close() {
    return super.close();
  }
}
