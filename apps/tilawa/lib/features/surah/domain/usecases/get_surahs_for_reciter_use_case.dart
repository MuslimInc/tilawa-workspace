import 'package:injectable/injectable.dart';
import '../entities/surah_entity.dart';
import '../repositories/surah_repository.dart';

@Singleton()
class GetSurahsForReciterUseCase {
  const GetSurahsForReciterUseCase(this._surahRepository);

  final SurahRepository _surahRepository;

  Future<List<SurahEntity>> call(String reciterName) async {
    return _surahRepository.getSurahsForReciter(reciterName);
  }
}
