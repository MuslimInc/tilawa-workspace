import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/genui_schema.dart';
import '../../domain/failures/genui_failure.dart';
import '../../domain/repositories/genui_repository.dart';
import 'genui_transport.dart';

/// Deterministic transport that returns canned documents.
///
/// Used as the default transport while the live Gemini path is disabled, and as
/// the test double for the whole pipeline. By default it returns a minimal,
/// valid Smart Quran Plan document whose content references trusted ids only.
class GenUiFakeTransport implements GenUiTransport {
  const GenUiFakeTransport({this.document, this.failure});

  /// Override payload. When null, a built-in valid plan document is returned.
  final String? document;

  /// When set, the transport fails with this instead of returning a document.
  final GenUiFailure? failure;

  @override
  GenUiResult<String> requestDocument(GenUiSurfaceRequest request) async {
    final GenUiFailure? f = failure;
    if (f != null) return Left(f);
    return Right(document ?? _defaultPlanDocument);
  }
}

/// A minimal, schema-valid Smart Quran Plan. Every figure references trusted
/// ids; the renderer resolves the actual ayah/plan content locally.
const String _defaultPlanDocument =
    '''
{
  "schemaVersion": "${GenUiSchema.version}",
  "assistantNote": "Here is a gentle plan for today.",
  "nodes": [
    {
      "type": "SectionStack",
      "children": [
        { "type": "PlanHeader", "props": { "titleKey": "smartQuranPlan" } },
        {
          "type": "WirdCard",
          "props": { "planId": "today", "rangeLabel": "Al-Baqarah 1-5" }
        },
        {
          "type": "AyahReferenceCard",
          "props": { "surah": 2, "ayah": 255 }
        },
        {
          "type": "ActionButton",
          "props": { "labelKey": "startTodayWird" },
          "actionId": "startTodayWird"
        }
      ]
    }
  ]
}
''';
