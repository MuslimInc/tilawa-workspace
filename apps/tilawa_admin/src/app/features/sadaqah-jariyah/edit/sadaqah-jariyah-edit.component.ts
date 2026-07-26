import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  FormBuilder,
  FormGroup,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';

import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { TilawaCardComponent } from '../../../shared/components/tilawa-card/tilawa-card.component';
import { TilawaButtonComponent } from '../../../shared/components/tilawa-button/tilawa-button.component';
import { TilawaLoadingStateComponent } from '../../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../../shared/components/tilawa-error-state/tilawa-error-state.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { StatusLabelPipe } from '../../../core/i18n/status-label.pipe';
import { AuthFacade } from '../../../core/application/facades/auth.facade';
import { I18nService } from '../../../core/i18n/i18n.service';

import {
  DedicationRecord,
  DedicationWriteInput,
  DedicationsRepository,
} from '../shared/dedications.repository';
import {
  DEDICATION_RELATION_OPTIONS,
  DEDICATION_STATUS_OPTIONS,
  DedicationRelation,
  DedicationStatus,
} from '../shared/relation.options';
import {
  DedicationsPaths,
  FOUNDING_DEDICATION_ID,
} from '../shared/dedications.paths';
import { proposeSlugFromDisplayName } from '../shared/slug.util';

@Component({
  selector: 'app-sadaqah-jariyah-edit',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    PageHeaderComponent,
    TilawaCardComponent,
    TilawaButtonComponent,
    TilawaLoadingStateComponent,
    TilawaErrorStateComponent,
    TranslatePipe,
    StatusLabelPipe,
  ],
  templateUrl: './sadaqah-jariyah-edit.component.html',
})
export class SadaqahJariyahEditComponent implements OnInit {
  private readonly repository = inject(DedicationsRepository);
  private readonly authFacade = inject(AuthFacade);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly fb = inject(FormBuilder);
  private readonly i18n = inject(I18nService);

  readonly loading = signal(true);
  readonly saving = signal(false);
  readonly uploading = signal(false);
  readonly selectedPhotoName = signal<string | null>(null);
  readonly errorMessage = signal<string | null>(null);
  readonly successMessage = signal<string | null>(null);

  dedicationId: string | null = null;
  isCreateMode = true;
  previousSlug = '';
  wasPublished = false;
  foundingExists = false;
  slugLocked = false;
  foundingLocked = false;

  readonly relationOptions = DEDICATION_RELATION_OPTIONS;
  readonly statusOptions = DEDICATION_STATUS_OPTIONS;

  form: FormGroup = this.fb.group({
    displayName: ['', [Validators.required, Validators.maxLength(80)]],
    slug: ['', [Validators.required, Validators.maxLength(80)]],
    relation: [''],
    relationOther: ['', Validators.maxLength(40)],
    note: ['', Validators.maxLength(120)],
    photoStoragePath: [''],
    status: ['draft' as DedicationStatus, Validators.required],
    isFounding: [false],
    isFeatured: [false],
    sortOrder: [0, [Validators.required]],
    internalOpsNote: [''],
    channelRef: [''],
  });

  ngOnInit(): void {
    const routeId = this.route.snapshot.paramMap.get('id');
    this.isCreateMode = routeId === 'new' || !routeId;
    this.dedicationId = this.isCreateMode ? null : routeId;
    void this.initialize();
  }

  private async initialize(): Promise<void> {
    this.loading.set(true);
    this.errorMessage.set(null);
    try {
      const foundingId = await this.repository.getFoundingDedicationId();
      this.foundingExists = foundingId != null;

      if (this.isCreateMode) {
        this.foundingLocked = this.foundingExists;
        this.form.patchValue({ isFounding: false });
        if (this.foundingExists) {
          this.form.get('isFounding')?.disable();
        }
        return;
      }

      const record = await this.repository.getDedication(this.dedicationId!);
      if (!record) {
        this.errorMessage.set(this.i18n.t('sadaqahJariyah_error_notFound'));
        return;
      }

      const ops = await this.repository.getPrivateOps(record.id);
      this.previousSlug = record.slug;
      this.wasPublished = record.status === 'published' || record.publishedAt != null;
      this.slugLocked = this.wasPublished;
      this.foundingLocked =
        record.id === FOUNDING_DEDICATION_ID ||
        (this.foundingExists && record.id !== foundingId);

      this.form.patchValue({
        displayName: record.displayName,
        slug: record.slug,
        relation: record.relation ?? '',
        relationOther: record.relationOther ?? '',
        note: record.note ?? '',
        photoStoragePath: record.photoStoragePath ?? '',
        status: record.status,
        isFounding: record.isFounding,
        isFeatured: record.isFeatured,
        sortOrder: record.sortOrder,
        internalOpsNote: ops.internalOpsNote,
        channelRef: ops.channelRef,
      });

      if (record.id === FOUNDING_DEDICATION_ID) {
        this.form.get('isFounding')?.disable();
      } else if (this.foundingExists && !record.isFounding) {
        this.form.get('isFounding')?.disable();
      }

      if (this.slugLocked) {
        this.form.get('slug')?.disable();
      }
    } catch (error: unknown) {
      this.errorMessage.set(
        error instanceof Error ? error.message : 'Failed to load dedication',
      );
    } finally {
      this.loading.set(false);
    }
  }

  onDisplayNameBlur(): void {
    if (this.slugLocked) {
      return;
    }
    const slugControl = this.form.get('slug');
    if (!slugControl || (slugControl.dirty && slugControl.value)) {
      return;
    }
    const proposed = proposeSlugFromDisplayName(this.form.value.displayName ?? '');
    if (proposed) {
      slugControl.setValue(proposed);
    }
  }

  showRelationOther(): boolean {
    return this.form.value.relation === 'other';
  }

  async onPhotoSelected(event: Event): Promise<void> {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file || !this.dedicationId) {
      return;
    }

    this.selectedPhotoName.set(file.name);
    this.uploading.set(true);
    this.errorMessage.set(null);
    try {
      const path = await this.repository.uploadPhoto(this.dedicationId, file);
      this.form.patchValue({ photoStoragePath: path });
      this.form.markAsDirty();
      this.successMessage.set(this.i18n.t('sadaqahJariyah_photoUploaded'));
      setTimeout(() => this.successMessage.set(null), 3000);
    } catch (error: unknown) {
      this.errorMessage.set(
        error instanceof Error ? error.message : 'Photo upload failed',
      );
      this.selectedPhotoName.set(null);
    } finally {
      this.uploading.set(false);
      input.value = '';
    }
  }

  buildWriteInput(): DedicationWriteInput {
    const raw = this.form.getRawValue();
    const relation = (raw.relation as DedicationRelation | '') || null;
    return {
      displayName: String(raw.displayName ?? ''),
      slug: String(raw.slug ?? ''),
      relation,
      relationOther: relation === 'other' ? String(raw.relationOther ?? '') : null,
      note: String(raw.note ?? '') || null,
      photoStoragePath: String(raw.photoStoragePath ?? '') || null,
      status: raw.status as DedicationStatus,
      isFounding: Boolean(raw.isFounding),
      isFeatured: Boolean(raw.isFeatured),
      sortOrder: Math.trunc(Number(raw.sortOrder ?? 0)),
    };
  }

  async save(): Promise<void> {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const adminId = this.authFacade.session()?.uid;
    if (!adminId) {
      this.errorMessage.set(this.i18n.t('login_adminRequired'));
      return;
    }

    this.saving.set(true);
    this.errorMessage.set(null);
    this.successMessage.set(null);

    try {
      const input = this.buildWriteInput();

      if (this.isCreateMode) {
        const id = await this.repository.createDedication(input, adminId);
        await this.repository.savePrivateOps(id, {
          internalOpsNote: String(this.form.value.internalOpsNote ?? ''),
          channelRef: String(this.form.value.channelRef ?? ''),
        });
        await this.router.navigate(['/sadaqah-jariyah', id]);
        return;
      }

      await this.repository.updateDedication(
        this.dedicationId!,
        input,
        this.previousSlug,
        this.wasPublished,
        adminId,
      );
      await this.repository.savePrivateOps(this.dedicationId!, {
        internalOpsNote: String(this.form.value.internalOpsNote ?? ''),
        channelRef: String(this.form.value.channelRef ?? ''),
      });
      this.previousSlug = input.slug;
      this.wasPublished =
        input.status === 'published' || this.wasPublished;
      this.slugLocked = this.wasPublished;
      if (this.slugLocked) {
        this.form.get('slug')?.disable();
      }
      this.form.markAsPristine();
      this.successMessage.set(this.i18n.t('sadaqahJariyah_saveSuccess'));
      setTimeout(() => this.successMessage.set(null), 3000);
    } catch (error: unknown) {
      const key = error instanceof Error ? error.message : '';
      this.errorMessage.set(
        key.startsWith('sadaqahJariyah_') ? this.i18n.t(key) : key || 'Save failed',
      );
    } finally {
      this.saving.set(false);
    }
  }

  async archive(): Promise<void> {
    if (this.isCreateMode || !this.dedicationId) {
      return;
    }
    const adminId = this.authFacade.session()?.uid;
    if (!adminId) {
      return;
    }
    this.saving.set(true);
    this.errorMessage.set(null);
    try {
      await this.repository.archiveDedication(this.dedicationId, adminId);
      this.form.patchValue({ status: 'archived' });
      this.form.markAsDirty();
      this.successMessage.set(this.i18n.t('sadaqahJariyah_archivedSuccess'));
    } catch (error: unknown) {
      const key = error instanceof Error ? error.message : '';
      this.errorMessage.set(
        key.startsWith('sadaqahJariyah_') ? this.i18n.t(key) : key || 'Archive failed',
      );
    } finally {
      this.saving.set(false);
    }
  }

  pageTitle(): string {
    return this.isCreateMode
      ? this.i18n.t('sadaqahJariyah_createTitle')
      : this.i18n.t('sadaqahJariyah_editTitle');
  }

  expectedPhotoPath(): string {
    if (!this.dedicationId) {
      return DedicationsPaths.photoPath('<id>');
    }
    return DedicationsPaths.photoPath(this.dedicationId);
  }
}

