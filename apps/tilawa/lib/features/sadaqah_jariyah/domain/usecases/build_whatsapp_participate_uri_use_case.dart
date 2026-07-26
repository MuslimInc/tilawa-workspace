import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../entities/sadaqah_jariyah_config.dart';

class BuildWhatsappParticipateUriParams {
  const BuildWhatsappParticipateUriParams({
    required this.config,
    required this.languageCode,
  });

  final SadaqahJariyahConfig config;
  final String languageCode;
}

@lazySingleton
class BuildWhatsappParticipateUriUseCase
    implements UseCase<Uri, BuildWhatsappParticipateUriParams> {
  @override
  Future<Either<Failure, Uri>> call(
    BuildWhatsappParticipateUriParams params,
  ) async {
    final String digits = params.config.whatsappE164.replaceAll(
      RegExp(r'[^\d]'),
      '',
    );
    if (digits.isEmpty) {
      return const Left(ValidationFailure('whatsappUnavailable'));
    }
    final String text = params.config.messageTemplateForLanguageCode(
      params.languageCode,
    );
    final Uri uri = Uri.https('wa.me', '/$digits', <String, String>{
      'text': text,
    });
    return Right(uri);
  }
}
