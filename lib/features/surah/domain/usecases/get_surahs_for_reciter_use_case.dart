import 'package:injectable/injectable.dart';
import 'package:muzakri/features/surah/domain/entities/surah.dart';
import 'package:muzakri/features/surah/domain/repositories/surah_repository.dart';

@Singleton()
class GetSurahsForReciterUseCase {
  const GetSurahsForReciterUseCase(this._surahRepository);

  final SurahRepository _surahRepository;

  Future<List<Surah>> call(String reciterName) async {
    return await _surahRepository.getSurahsForReciter(reciterName);
  }
}
