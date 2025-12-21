import 'package:injectable/injectable.dart';

import '../entities/download_item.dart';
import '../repositories/single_download_repository.dart';

@injectable
class ObserveDownloadProgressUseCase {
  ObserveDownloadProgressUseCase(this._repository);

  final SingleDownloadRepository _repository;

  Stream<DownloadItem> call(String downloadId) {
    return _repository.getDownloadProgress(downloadId);
  }
}
