import 'package:injectable/injectable.dart';

import '../entities/download_item.dart';
import '../repositories/single_download_repository.dart';

@injectable
class ObserveReciterDownloadsUseCase {
  ObserveReciterDownloadsUseCase(this._repository);

  final SingleDownloadRepository _repository;

  Stream<DownloadItem> call(String reciterName) {
    return _repository.downloadUpdates.where(
      (item) => item.reciterName == reciterName,
    );
  }
}
