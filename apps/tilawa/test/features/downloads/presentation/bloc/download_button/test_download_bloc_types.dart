sealed class TestDownloadEvent {}

class TestInitialize extends TestDownloadEvent {}

class TestProgressUpdated extends TestDownloadEvent {
  TestProgressUpdated(this.progress);
  final double progress;
}

sealed class TestDownloadState {}

class TestInitial extends TestDownloadState {}

class TestDownloading extends TestDownloadState {
  TestDownloading(this.progress);
  final double progress;
}
