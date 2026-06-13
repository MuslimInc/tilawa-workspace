import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'test_download_bloc_types.dart';

/// Bloc WITHOUT the isClosed check - this WILL crash
class BlocWithoutFix extends Bloc<TestDownloadEvent, TestDownloadState> {
  BlocWithoutFix({required this._progressStream}) : super(TestInitial()) {
    on<TestInitialize>((event, emit) async {
      emit(TestDownloading(0.0));
      _subscription = _progressStream.listen((progress) {
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
}
