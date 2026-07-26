import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/entities/sadaqah_jariyah_config.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/usecases/build_whatsapp_participate_uri_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

void main() {
  final BuildWhatsappParticipateUriUseCase useCase =
      BuildWhatsappParticipateUriUseCase();

  test('builds wa.me uri with digits and text', () async {
    final Either<Failure, Uri> result = await useCase(
      const BuildWhatsappParticipateUriParams(
        config: SadaqahJariyahConfig(
          whatsappE164: '+20 100 123 4567',
          messageTemplateEn: 'Hello',
        ),
        languageCode: 'en',
      ),
    );

    check(result.isRight()).isTrue();
    final Uri uri = result.getOrElse(Uri.new);
    check(uri.host).equals('wa.me');
    check(uri.path).equals('/201001234567');
    check(uri.queryParameters['text']).equals('Hello');
  });

  test('empty phone returns ValidationFailure', () async {
    final Either<Failure, Uri> result = await useCase(
      const BuildWhatsappParticipateUriParams(
        config: SadaqahJariyahConfig(whatsappE164: ''),
        languageCode: 'en',
      ),
    );

    check(result.isLeft()).isTrue();
    final Failure failure = result.fold(
      (Failure l) => l,
      (_) => throw StateError('expected left'),
    );
    check(failure).isA<ValidationFailure>();
  });
}
