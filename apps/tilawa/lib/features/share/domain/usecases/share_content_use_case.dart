import 'package:injectable/injectable.dart';

import '../entities/share_content.dart';
import '../repositories/share_repository.dart';

@injectable
class ShareContentUseCase {
  ShareContentUseCase(this._repository);
  final ShareRepository _repository;

  Future<void> call(ShareContent content) {
    return _repository.shareContent(content);
  }

  Future<String> exportContent(ShareContent content) {
    return _repository.exportContent(content);
  }

  Future<void> cleanup() {
    return _repository.cleanup();
  }
}
