import 'package:tilawa_core/errors/failures.dart';

/// Feature failure keys mapped onto core [Failure] subtypes.
///
/// [Failure] is sealed in `tilawa_core`, so this feature cannot subclass it.
abstract final class SadaqahJariyahFailures {
  static const Failure network = NetworkFailure('sadaqahJariyahUnavailable');
  static const Failure parse = UnexpectedFailure('sadaqahJariyahParse');
  static const Failure whatsappUnavailable = ValidationFailure(
    'whatsappUnavailable',
  );
}
