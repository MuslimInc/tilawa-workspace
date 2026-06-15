import 'package:injectable/injectable.dart';

import '../entities/recitation_target.dart';
import '../repositories/recitation_verse_repository.dart';

@lazySingleton
class GetPageRecitationTargetsUseCase {
  const GetPageRecitationTargetsUseCase(this._repository);

  final RecitationVerseRepository _repository;

  List<RecitationTarget> call(int pageNumber) {
    return _repository.getTargetsForPage(pageNumber);
  }
}
