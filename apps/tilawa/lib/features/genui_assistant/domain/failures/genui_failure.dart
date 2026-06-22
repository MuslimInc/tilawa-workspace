import 'package:dartz_plus/dartz_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:tilawa_core/errors/failures.dart';

/// Internal result type for the GenUI pipeline (transport + parser).
///
/// Kept separate from the workspace `ResultFuture` so the pipeline can carry
/// rich, GenUI-specific failure variants. The repository maps these to the core
/// [Failure] hierarchy ([GenUiFailure.toFailure]) at its boundary, because the
/// workspace `Failure` type is sealed and cannot be extended here.
typedef GenUiResult<T> = Future<Either<GenUiFailure, T>>;

/// Failures specific to the AI-generated UI pipeline.
///
/// Every variant is recoverable: the renderer responds with a safe fallback,
/// never a crash.
sealed class GenUiFailure extends Equatable {
  const GenUiFailure([this.message]);

  final String? message;

  /// Maps to the workspace [Failure] hierarchy at the repository boundary.
  Failure toFailure() => switch (this) {
    GenUiTransportFailure() => ServerFailure(message),
    GenUiParseFailure() => ValidationFailure(message),
    GenUiSchemaVersionFailure() => ValidationFailure(message),
    GenUiDisabledFailure() => ValidationFailure(message),
  };

  @override
  List<Object?> get props => <Object?>[message];
}

/// The transport could not produce a document (network, model, timeout).
final class GenUiTransportFailure extends GenUiFailure {
  const GenUiTransportFailure([super.message]);
}

/// The payload was not valid JSON or did not match the document shape.
final class GenUiParseFailure extends GenUiFailure {
  const GenUiParseFailure([super.message]);
}

/// The payload was structurally valid but tagged with an unsupported
/// `schemaVersion`. The whole document is rejected.
final class GenUiSchemaVersionFailure extends GenUiFailure {
  const GenUiSchemaVersionFailure({
    required this.expected,
    required this.received,
  }) : super(
         'Unsupported GenUI schema version: '
         'expected $expected, received $received',
       );

  final String expected;
  final String? received;

  @override
  List<Object?> get props => <Object?>[message, expected, received];
}

/// The feature is disabled by the launch flag, so no transport is wired.
final class GenUiDisabledFailure extends GenUiFailure {
  const GenUiDisabledFailure([super.message = 'GenUI assistant is disabled']);
}
