import 'package:flutter/widgets.dart';
import 'package:tilawa/core/extensions.dart';

import '../../domain/enums/dedication_relation.dart';

String? localizedDedicationRelation(
  BuildContext context,
  DedicationRelation? relation, {
  String? relationOther,
}) {
  if (relation == null) {
    return null;
  }
  final l10n = context.l10n;
  return switch (relation) {
    DedicationRelation.father => l10n.dedicationRelationFather,
    DedicationRelation.mother => l10n.dedicationRelationMother,
    DedicationRelation.brother => l10n.dedicationRelationBrother,
    DedicationRelation.sister => l10n.dedicationRelationSister,
    DedicationRelation.husband => l10n.dedicationRelationHusband,
    DedicationRelation.wife => l10n.dedicationRelationWife,
    DedicationRelation.son => l10n.dedicationRelationSon,
    DedicationRelation.daughter => l10n.dedicationRelationDaughter,
    DedicationRelation.friend => l10n.dedicationRelationFriend,
    DedicationRelation.other => () {
      final String? other = relationOther?.trim();
      if (other == null || other.isEmpty) {
        return l10n.dedicationRelationOther;
      }
      return other;
    }(),
  };
}
