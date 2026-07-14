import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  FormBuilder,
  FormGroup,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';

import { PageHeaderComponent } from '../../shared/components/page-header/page-header.component';
import { TilawaCardComponent } from '../../shared/components/tilawa-card/tilawa-card.component';
import { TilawaButtonComponent } from '../../shared/components/tilawa-button/tilawa-button.component';
import { TilawaLoadingStateComponent } from '../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../shared/components/tilawa-error-state/tilawa-error-state.component';
import { ConfirmDialogComponent } from '../../shared/components/confirm-dialog/confirm-dialog.component';
import { TranslatePipe } from '../../core/i18n/translate.pipe';
import { I18nService } from '../../core/i18n/i18n.service';

import { AppVersionFacade } from './app-version.facade';
import { ForcedUpdateConfig } from './forced-update-config.mapping';

@Component({
  selector: 'app-app-version',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    PageHeaderComponent,
    TilawaCardComponent,
    TilawaButtonComponent,
    TilawaLoadingStateComponent,
    TilawaErrorStateComponent,
    ConfirmDialogComponent,
    TranslatePipe,
  ],
  templateUrl: './app-version.component.html',
})
export class AppVersionComponent implements OnInit {
  readonly facade = inject(AppVersionFacade);
  private readonly fb = inject(FormBuilder);
  private readonly i18n = inject(I18nService);

  loading$ = this.facade.loading$;
  saving$ = this.facade.saving$;
  error$ = this.facade.error$;
  successMessage$ = this.facade.successMessage$;

  confirmOpen = false;

  form: FormGroup = this.fb.group({
    androidMinBuildNumber: [0, [Validators.required, Validators.min(0)]],
    iosMinBuildNumber: [0, [Validators.required, Validators.min(0)]],
  });

  ngOnInit(): void {
    void this.loadForm();
  }

  openSaveConfirm(): void {
    if (this.form.invalid || this.form.pristine) {
      this.form.markAllAsTouched();
      return;
    }
    this.confirmOpen = true;
  }

  cancelSave(): void {
    this.confirmOpen = false;
  }

  async confirmSave(): Promise<void> {
    if (this.form.invalid) {
      return;
    }

    const payload: ForcedUpdateConfig = {
      androidMinBuildNumber: Math.trunc(
        Number(this.form.value.androidMinBuildNumber),
      ),
      iosMinBuildNumber: Math.trunc(Number(this.form.value.iosMinBuildNumber)),
    };

    if (
      !Number.isFinite(payload.androidMinBuildNumber) ||
      !Number.isFinite(payload.iosMinBuildNumber) ||
      payload.androidMinBuildNumber < 0 ||
      payload.iosMinBuildNumber < 0
    ) {
      this.form.markAllAsTouched();
      return;
    }

    try {
      await this.facade.saveConfig(payload);
      this.form.markAsPristine();
      this.confirmOpen = false;
    } catch {
      // Keep dialog open so admin can retry after reading error$.
    }
  }

  confirmMessage(): string {
    const android = String(this.form.value.androidMinBuildNumber ?? '');
    const ios = String(this.form.value.iosMinBuildNumber ?? '');
    return this.i18n.t('forcedUpdate_confirmMessage', { android, ios });
  }

  private async loadForm(): Promise<void> {
    const config = await this.facade.loadConfig();
    this.form.patchValue(config);
    this.form.markAsPristine();
  }
}
