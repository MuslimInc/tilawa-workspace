import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:tilawa/features/downloads/data/services/flutter_downloader_wrapper.dart';
import 'package:tilawa/features/downloads/data/services/helpers/download_file_helper.dart';
import 'package:tilawa/features/downloads/data/services/helpers/download_isolate_manager.dart';

@GenerateMocks([
  FlutterDownloaderWrapper,
  DownloadFileHelper,
  DownloadIsolateManager,
])
void main() {
  testWidgets('Test for flutter_downloader_wrapper.dart', (
    WidgetTester tester,
  ) async {
    // This test file primarily exists to generate mocks
  });
}
