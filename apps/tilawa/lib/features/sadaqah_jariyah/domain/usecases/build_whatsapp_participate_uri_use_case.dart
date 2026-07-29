import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../entities/sadaqah_jariyah_config.dart';
import '../failures/sadaqah_jariyah_failure.dart';

class BuildWhatsappParticipateUriParams {
  const BuildWhatsappParticipateUriParams({
    required this.config,
    required this.languageCode,
  });

  final SadaqahJariyahConfig config;
  final String languageCode;
}

class BuildWhatsappParticipateUriUseCase
    implements UseCase<Uri, BuildWhatsappParticipateUriParams> {
  @override
  Future<Either<Failure, Uri>> call(
    BuildWhatsappParticipateUriParams params,
  ) async {
    final String whatsappE164 = params.config.whatsappE164.trim();
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(whatsappE164)) {
      return const Left(SadaqahJariyahFailures.whatsappUnavailable);
    }
    final String digits = whatsappE164.substring(1);
    final String text = params.config.messageTemplateForLanguageCode(
      params.languageCode,
    );
    final Uri uri = Uri.https('wa.me', '/$digits', <String, String>{
      'text': text,
    });
    return Right(uri);
  }
}
