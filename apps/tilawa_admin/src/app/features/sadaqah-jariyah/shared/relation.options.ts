export type DedicationRelation =
  | 'father'
  | 'mother'
  | 'brother'
  | 'sister'
  | 'husband'
  | 'wife'
  | 'son'
  | 'daughter'
  | 'friend'
  | 'other';

export const DEDICATION_RELATION_OPTIONS: readonly {
  value: DedicationRelation;
  labelKey: string;
}[] = [
  { value: 'father', labelKey: 'sadaqahJariyah_relation_father' },
  { value: 'mother', labelKey: 'sadaqahJariyah_relation_mother' },
  { value: 'brother', labelKey: 'sadaqahJariyah_relation_brother' },
  { value: 'sister', labelKey: 'sadaqahJariyah_relation_sister' },
  { value: 'husband', labelKey: 'sadaqahJariyah_relation_husband' },
  { value: 'wife', labelKey: 'sadaqahJariyah_relation_wife' },
  { value: 'son', labelKey: 'sadaqahJariyah_relation_son' },
  { value: 'daughter', labelKey: 'sadaqahJariyah_relation_daughter' },
  { value: 'friend', labelKey: 'sadaqahJariyah_relation_friend' },
  { value: 'other', labelKey: 'sadaqahJariyah_relation_other' },
];

export type DedicationStatus = 'draft' | 'published' | 'archived';

export const DEDICATION_STATUS_OPTIONS: readonly DedicationStatus[] = [
  'draft',
  'published',
  'archived',
];
