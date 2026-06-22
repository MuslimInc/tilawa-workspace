import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../../domain/entities/genui_document.dart';
import '../../domain/failures/genui_failure.dart';
import '../../domain/repositories/genui_repository.dart';
import '../datasources/genui_transport.dart';
import '../parser/genui_parser.dart';

/// Default repository: fetch raw document from the transport, validate it
/// through the parser, and map any GenUI-specific failure onto the workspace
/// [Failure] hierarchy at the boundary. The model never escapes this layer.
class GenUiRepositoryImpl implements GenUiRepository {
  const GenUiRepositoryImpl({
    required this._transport,
    this._parser = const GenUiParser(),
  });

  final GenUiTransport _transport;
  final GenUiParser _parser;

  @override
  ResultFuture<GenUiDocument> requestSurface(
    GenUiSurfaceRequest request,
  ) async {
    final Either<GenUiFailure, String> raw = await _transport.requestDocument(
      request,
    );
    final Either<GenUiFailure, GenUiDocument> document = raw.fold(
      Left.new,
      _parser.parse,
    );
    return document.fold(
      (GenUiFailure failure) =>
          Left<Failure, GenUiDocument>(failure.toFailure()),
      Right<Failure, GenUiDocument>.new,
    );
  }
}
