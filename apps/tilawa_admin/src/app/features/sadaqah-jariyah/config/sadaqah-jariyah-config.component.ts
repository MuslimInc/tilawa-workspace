import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  FormBuilder,
  FormGroup,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';

import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { TilawaCardComponent } from '../../../shared/components/tilawa-card/tilawa-card.component';
import { TilawaButtonComponent } from '../../../shared/components/tilawa-button/tilawa-button.component';
import { TilawaLoadingStateComponent } from '../../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../../shared/components/tilawa-error-state/tilawa-error-state.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';

import {
  DedicationsRepository,
  SadaqahJariyahConfigRecord,
} from '../shared/dedications.repository';

@Component({
  selector: 'app-sadaqah-jariyah-config',
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
  ],
  templateUrl: './sadaqah-jariyah-config.component.html',
})
export class SadaqahJariyahConfigComponent implements OnInit {
  private readonly repository = inject(DedicationsRepository);
  private readonly fb = inject(FormBuilder);

  loading = true;
  saving = false;
  errorMessage: string | null = null;
  successMessage: string | null = null;

  form: FormGroup = this.fb.group({
    featureTitleAr: ['', Validators.required],
    featureTitleEn: ['', Validators.required],
    featureSubtitleAr: [''],
    featureSubtitleEn: [''],
    whatsappE164: [''],
    messageTemplateAr: ['', Validators.required],
    messageTemplateEn: ['', Validators.required],
    featureEnabled: [true],
  });

  ngOnInit(): void {
    void this.load();
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.errorMessage = null;
    try {
      const config = await this.repository.getConfig();
      this.form.patchValue(config);
      this.form.markAsPristine();
    } catch (error: unknown) {
      this.errorMessage =
        error instanceof Error ? error.message : 'Failed to load config';
    } finally {
      this.loading = false;
    }
  }

  async save(): Promise<void> {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.saving = true;
    this.errorMessage = null;
    this.successMessage = null;

    try {
      const payload = this.form.value as SadaqahJariyahConfigRecord;
      await this.repository.saveConfig(payload);
      this.form.markAsPristine();
      this.successMessage = 'sadaqahJariyah_configSaveSuccess';
      setTimeout(() => (this.successMessage = null), 3000);
    } catch (error: unknown) {
      this.errorMessage =
        error instanceof Error ? error.message : 'Failed to save config';
    } finally {
      this.saving = false;
    }
  }
}
