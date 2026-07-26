import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/sadaqah_jariyah/data/mappers/sadaqah_jariyah_config_mapper.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/entities/sadaqah_jariyah_config.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/enums/dedication_relation.dart';

void main() {
  test('mapSadaqahJariyahConfig null returns defaults', () {
    final SadaqahJariyahConfig config = mapSadaqahJariyahConfig(null);
    check(config.featureTitleEn).equals(SadaqahJariyahConfig.defaultTitleEn);
    check(config.featureEnabled).isTrue();
    check(config.whatsappE164).equals(SadaqahJariyahConfig.defaultWhatsappE164);
  });

  test('mapSadaqahJariyahConfig empty titles keep empty for UI fallback', () {
    final SadaqahJariyahConfig config = mapSadaqahJariyahConfig(
      <String, dynamic>{
        'featureTitleEn': '',
        'featureTitleAr': '',
        'featureEnabled': false,
      },
    );
    check(config.titleForLanguageCode('en')).equals(
      SadaqahJariyahConfig.defaultTitleEn,
    );
    check(config.featureEnabled).isFalse();
  });

  test('DedicationRelation.tryParse unknown returns null', () {
    check(DedicationRelation.tryParse('cousin')).isNull();
    check(DedicationRelation.tryParse('father')).equals(
      DedicationRelation.father,
    );
  });
}
