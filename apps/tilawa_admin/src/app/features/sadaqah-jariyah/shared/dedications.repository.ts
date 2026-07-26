import { Injectable, inject } from '@angular/core';
import {
  Firestore,
  Timestamp,
  collection,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  runTransaction,
  serverTimestamp,
  setDoc,
  where,
} from '@angular/fire/firestore';
import { Storage, ref, uploadBytes } from '@angular/fire/storage';

import {
  DedicationsPaths,
  FOUNDING_DEDICATION_ID,
} from './dedications.paths';
import {
  DedicationRelation,
  DedicationStatus,
} from './relation.options';
import { isValidSlug, noteContainsUrl } from './slug.util';

export interface DedicationRecord {
  id: string;
  displayName: string;
  slug: string;
  relation: DedicationRelation | null;
  relationOther: string | null;
  note: string | null;
  photoStoragePath: string | null;
  status: DedicationStatus;
  isFounding: boolean;
  isFeatured: boolean;
  sortOrder: number;
  publishedAt: Date | null;
  createdAt: Date | null;
  updatedAt: Date | null;
  createdByAdminId: string;
  updatedByAdminId: string;
}

export interface DedicationWriteInput {
  displayName: string;
  slug: string;
  relation: DedicationRelation | null;
  relationOther: string | null;
  note: string | null;
  photoStoragePath: string | null;
  status: DedicationStatus;
  isFounding: boolean;
  isFeatured: boolean;
  sortOrder: number;
}

export interface PrivateOpsRecord {
  internalOpsNote: string;
  channelRef: string;
}

export interface SadaqahJariyahConfigRecord {
  featureTitleAr: string;
  featureTitleEn: string;
  featureSubtitleAr: string;
  featureSubtitleEn: string;
  whatsappE164: string;
  messageTemplateAr: string;
  messageTemplateEn: string;
  featureEnabled: boolean;
}

const DEFAULT_CONFIG: SadaqahJariyahConfigRecord = {
  featureTitleAr: 'صدقة جارية',
  featureTitleEn: 'Sadaqah Jariyah',
  featureSubtitleAr: 'صدقة جارية',
  featureSubtitleEn: 'Sadaqah Jariyah',
  whatsappE164: '+201060099009',
  messageTemplateAr:
    'السلام عليكم،\nأريد إضافة اسم إلى قائمة الصدقة الجارية في أنا مسلم.\n\nاسم المتوفى:\nصلة القرابة (اختياري):\nملاحظة قصيرة (اختياري):\n\nيرجى إضافتهم إلى القائمة. أسأل الله القبول.',
  messageTemplateEn:
    'Assalamu alaikum,\nI want to add a person to the Sadaqah Jariyah list in MeMuslim.\n\nDeceased name:\nRelation (optional):\nShort note (optional):\n\nPlease add them to the list. May Allah accept.',
  featureEnabled: true,
};

function asDate(value: unknown): Date | null {
  if (value instanceof Timestamp) {
    return value.toDate();
  }
  if (value instanceof Date) {
    return value;
  }
  return null;
}

function asInt(value: unknown): number {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.trunc(value);
  }
  if (typeof value === 'string' && value.trim().length > 0) {
    const parsed = Number.parseInt(value, 10);
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

function asString(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

function parseRelation(value: unknown): DedicationRelation | null {
  if (typeof value !== 'string') {
    return null;
  }
  const allowed: DedicationRelation[] = [
    'father',
    'mother',
    'brother',
    'sister',
    'husband',
    'wife',
    'son',
    'daughter',
    'friend',
    'other',
  ];
  return allowed.includes(value as DedicationRelation)
    ? (value as DedicationRelation)
    : null;
}

function parseStatus(value: unknown): DedicationStatus {
  if (value === 'published' || value === 'archived') {
    return value;
  }
  return 'draft';
}

function mapDedication(id: string, data: Record<string, unknown>): DedicationRecord {
  return {
    id,
    displayName: asString(data['displayName']).trim(),
    slug: asString(data['slug']).trim(),
    relation: parseRelation(data['relation']),
    relationOther: asString(data['relationOther']).trim() || null,
    note: asString(data['note']).trim() || null,
    photoStoragePath: asString(data['photoStoragePath']).trim() || null,
    status: parseStatus(data['status']),
    isFounding: data['isFounding'] === true,
    isFeatured: data['isFeatured'] === true,
    sortOrder: asInt(data['sortOrder']),
    publishedAt: asDate(data['publishedAt']),
    createdAt: asDate(data['createdAt']),
    updatedAt: asDate(data['updatedAt']),
    createdByAdminId: asString(data['createdByAdminId']),
    updatedByAdminId: asString(data['updatedByAdminId']),
  };
}

function mapConfig(data: Record<string, unknown> | undefined): SadaqahJariyahConfigRecord {
  if (!data) {
    return { ...DEFAULT_CONFIG };
  }
  return {
    featureTitleAr: asString(data['featureTitleAr']) || DEFAULT_CONFIG.featureTitleAr,
    featureTitleEn: asString(data['featureTitleEn']) || DEFAULT_CONFIG.featureTitleEn,
    featureSubtitleAr:
      asString(data['featureSubtitleAr']) || DEFAULT_CONFIG.featureSubtitleAr,
    featureSubtitleEn:
      asString(data['featureSubtitleEn']) || DEFAULT_CONFIG.featureSubtitleEn,
    whatsappE164: asString(data['whatsappE164']),
    messageTemplateAr:
      asString(data['messageTemplateAr']) || DEFAULT_CONFIG.messageTemplateAr,
    messageTemplateEn:
      asString(data['messageTemplateEn']) || DEFAULT_CONFIG.messageTemplateEn,
    featureEnabled:
      typeof data['featureEnabled'] === 'boolean'
        ? data['featureEnabled']
        : DEFAULT_CONFIG.featureEnabled,
  };
}

export function validateDedicationInput(input: DedicationWriteInput): string | null {
  const displayName = input.displayName.trim();
  if (displayName.length < 1 || displayName.length > 80) {
    return 'sadaqahJariyah_error_displayName';
  }

  const slug = input.slug.trim();
  if (!isValidSlug(slug)) {
    return 'sadaqahJariyah_error_slugInvalid';
  }

  if (input.relation === 'other') {
    const relationOther = (input.relationOther ?? '').trim();
    if (relationOther.length < 1 || relationOther.length > 40) {
      return 'sadaqahJariyah_error_relationOther';
    }
  }

  const note = (input.note ?? '').trim();
  if (note.length > 120) {
    return 'sadaqahJariyah_error_noteLength';
  }
  if (noteContainsUrl(note)) {
    return 'sadaqahJariyah_error_noteUrl';
  }

  return null;
}

@Injectable({ providedIn: 'root' })
export class DedicationsRepository {
  private readonly firestore = inject(Firestore);
  private readonly storage = inject(Storage);

  async listDedications(statusFilter?: DedicationStatus | ''): Promise<DedicationRecord[]> {
    const col = collection(this.firestore, DedicationsPaths.collection);
    const q =
      statusFilter && statusFilter.length > 0
        ? query(col, where('status', '==', statusFilter), orderBy('updatedAt', 'desc'))
        : query(col, orderBy('updatedAt', 'desc'));
    const snap = await getDocs(q);
    return snap.docs.map((docSnap) =>
      mapDedication(docSnap.id, docSnap.data() as Record<string, unknown>),
    );
  }

  async getDedication(id: string): Promise<DedicationRecord | null> {
    const snap = await getDoc(doc(this.firestore, DedicationsPaths.collection, id));
    if (!snap.exists()) {
      return null;
    }
    return mapDedication(snap.id, snap.data() as Record<string, unknown>);
  }

  async getFoundingDedicationId(): Promise<string | null> {
    const col = collection(this.firestore, DedicationsPaths.collection);
    const snap = await getDocs(query(col, where('isFounding', '==', true)));
    if (snap.empty) {
      return null;
    }
    return snap.docs[0]?.id ?? null;
  }

  async getPrivateOps(dedicationId: string): Promise<PrivateOpsRecord> {
    const snap = await getDoc(
      doc(this.firestore, DedicationsPaths.privateOpsDoc(dedicationId)),
    );
    if (!snap.exists()) {
      return { internalOpsNote: '', channelRef: '' };
    }
    const data = snap.data() as Record<string, unknown>;
    return {
      internalOpsNote: asString(data['internalOpsNote']),
      channelRef: asString(data['channelRef']),
    };
  }

  async savePrivateOps(dedicationId: string, ops: PrivateOpsRecord): Promise<void> {
    await setDoc(
      doc(this.firestore, DedicationsPaths.privateOpsDoc(dedicationId)),
      {
        internalOpsNote: ops.internalOpsNote.trim(),
        channelRef: ops.channelRef.trim(),
        updatedAt: serverTimestamp(),
      },
      { merge: true },
    );
  }

  async createDedication(
    input: DedicationWriteInput,
    adminId: string,
  ): Promise<string> {
    const validationError = validateDedicationInput(input);
    if (validationError) {
      throw new Error(validationError);
    }

    if (input.isFounding) {
      const existingFounding = await this.getFoundingDedicationId();
      if (existingFounding) {
        throw new Error('sadaqahJariyah_error_foundingExists');
      }
    }

    const id = doc(collection(this.firestore, DedicationsPaths.collection)).id;
    const slug = input.slug.trim();
    const nowPublished = input.status === 'published';

    await runTransaction(this.firestore, async (txn) => {
      const slugRef = doc(this.firestore, DedicationsPaths.slugCollection, slug);
      const slugSnap = await txn.get(slugRef);
      if (slugSnap.exists()) {
        throw new Error('sadaqahJariyah_error_slugTaken');
      }

      const dedicationRef = doc(this.firestore, DedicationsPaths.collection, id);
      txn.set(slugRef, { dedicationId: id });
      txn.set(dedicationRef, {
        displayName: input.displayName.trim(),
        slug,
        relation: input.relation,
        relationOther:
          input.relation === 'other' ? (input.relationOther ?? '').trim() : null,
        note: (input.note ?? '').trim() || null,
        photoStoragePath: input.photoStoragePath,
        status: input.status,
        isFounding: input.isFounding,
        isFeatured: input.isFeatured,
        sortOrder: Math.trunc(input.sortOrder),
        publishedAt: nowPublished ? serverTimestamp() : null,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        createdByAdminId: adminId,
        updatedByAdminId: adminId,
      });
    });

    return id;
  }

  async updateDedication(
    id: string,
    input: DedicationWriteInput,
    previousSlug: string,
    wasPublished: boolean,
    adminId: string,
  ): Promise<void> {
    const validationError = validateDedicationInput(input);
    if (validationError) {
      throw new Error(validationError);
    }

    if (id === FOUNDING_DEDICATION_ID && !input.isFounding) {
      throw new Error('sadaqahJariyah_error_foundingLocked');
    }

    if (input.isFounding && id !== FOUNDING_DEDICATION_ID) {
      const existingFounding = await this.getFoundingDedicationId();
      if (existingFounding && existingFounding !== id) {
        throw new Error('sadaqahJariyah_error_foundingExists');
      }
    }

    const slug = input.slug.trim();
    if (wasPublished && slug !== previousSlug.trim()) {
      throw new Error('sadaqahJariyah_error_slugFrozen');
    }

    const existing = await this.getDedication(id);
    if (!existing) {
      throw new Error('sadaqahJariyah_error_notFound');
    }

    const nowPublished = input.status === 'published';
    const publishedAt =
      nowPublished && !existing.publishedAt ? serverTimestamp() : existing.publishedAt;

    await runTransaction(this.firestore, async (txn) => {
      const dedicationRef = doc(this.firestore, DedicationsPaths.collection, id);

      if (slug !== previousSlug.trim()) {
        const oldSlugRef = doc(
          this.firestore,
          DedicationsPaths.slugCollection,
          previousSlug.trim(),
        );
        const newSlugRef = doc(this.firestore, DedicationsPaths.slugCollection, slug);
        const newSlugSnap = await txn.get(newSlugRef);
        if (newSlugSnap.exists()) {
          throw new Error('sadaqahJariyah_error_slugTaken');
        }
        txn.delete(oldSlugRef);
        txn.set(newSlugRef, { dedicationId: id });
      }

      txn.set(
        dedicationRef,
        {
          displayName: input.displayName.trim(),
          slug,
          relation: input.relation,
          relationOther:
            input.relation === 'other' ? (input.relationOther ?? '').trim() : null,
          note: (input.note ?? '').trim() || null,
          photoStoragePath: input.photoStoragePath,
          status: input.status,
          isFounding: input.isFounding,
          isFeatured: input.isFeatured,
          sortOrder: Math.trunc(input.sortOrder),
          publishedAt,
          updatedAt: serverTimestamp(),
          updatedByAdminId: adminId,
        },
        { merge: true },
      );
    });
  }

  async archiveDedication(id: string, adminId: string): Promise<void> {
    if (id === FOUNDING_DEDICATION_ID) {
      throw new Error('sadaqahJariyah_error_foundingLocked');
    }
    await setDoc(
      doc(this.firestore, DedicationsPaths.collection, id),
      {
        status: 'archived',
        updatedAt: serverTimestamp(),
        updatedByAdminId: adminId,
      },
      { merge: true },
    );
  }

  async uploadPhoto(dedicationId: string, file: File): Promise<string> {
    const path = DedicationsPaths.photoPath(dedicationId);
    const contentType =
      file.type === 'image/jpeg' || file.type === 'image/jpg'
        ? 'image/jpeg'
        : 'image/webp';
    await uploadBytes(ref(this.storage, path), file, {
      contentType,
      cacheControl: 'public,max-age=31536000',
    });
    return path;
  }

  async getConfig(): Promise<SadaqahJariyahConfigRecord> {
    const snap = await getDoc(doc(this.firestore, DedicationsPaths.configDoc));
    return mapConfig(
      snap.exists() ? (snap.data() as Record<string, unknown>) : undefined,
    );
  }

  async saveConfig(config: SadaqahJariyahConfigRecord): Promise<void> {
    await setDoc(
      doc(this.firestore, DedicationsPaths.configDoc),
      {
        featureTitleAr: config.featureTitleAr.trim(),
        featureTitleEn: config.featureTitleEn.trim(),
        featureSubtitleAr: config.featureSubtitleAr.trim(),
        featureSubtitleEn: config.featureSubtitleEn.trim(),
        whatsappE164: config.whatsappE164.trim(),
        messageTemplateAr: config.messageTemplateAr,
        messageTemplateEn: config.messageTemplateEn,
        featureEnabled: config.featureEnabled,
        updatedAt: serverTimestamp(),
      },
      { merge: true },
    );
  }
}
