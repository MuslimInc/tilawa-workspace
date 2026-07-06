import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';

import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { TilawaCardComponent } from '../../../shared/components/tilawa-card/tilawa-card.component';
import { TilawaButtonComponent } from '../../../shared/components/tilawa-button/tilawa-button.component';
import { TilawaLoadingStateComponent } from '../../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../../shared/components/tilawa-error-state/tilawa-error-state.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';

import { GlobalSettingsFacade, PlatformConfig } from './global-settings.facade';

@Component({
  selector: 'app-global-settings',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    PageHeaderComponent,
    TilawaCardComponent,
    TilawaButtonComponent,
    TilawaLoadingStateComponent,
    TilawaErrorStateComponent,
    TranslatePipe
  ],
  templateUrl: './global-settings.component.html'
})
export class GlobalSettingsComponent implements OnInit {
  public facade = inject(GlobalSettingsFacade);
  private fb = inject(FormBuilder);

  loading$ = this.facade.loading$;
  saving$ = this.facade.saving$;
  error$ = this.facade.error$;
  successMessage$ = this.facade.successMessage$;

  settingsForm: FormGroup = this.fb.group({
    quranSessionsEnabled: [false],
    studentEntryEnabled: [false],
    bookingEnabled: [false],
    sessionMode: ['videoOnly', Validators.required],
    defaultBookingMode: ['requiresTutorApproval', Validators.required],
    defaultJoinWindowLeadMs: [0, [Validators.required, Validators.min(0)]],
    defaultTutorApprovalSlaMs: [0, [Validators.required, Validators.min(0)]],
    defaultMinBookingNoticeMs: [0, [Validators.required, Validators.min(0)]],
    defaultMaxUpcomingPerStudent: [0, [Validators.required, Validators.min(1)]]
  });

  ngOnInit() {
    this.facade.getConfig().subscribe(config => {
      if (config) {
        this.settingsForm.patchValue(config);
        this.settingsForm.markAsPristine();
      }
    });
  }

  async save() {
    if (this.settingsForm.invalid) return;

    try {
      await this.facade.saveConfig(this.settingsForm.value as PlatformConfig);
      this.settingsForm.markAsPristine();
    } catch (e) {
      // Facade handles the error
    }
  }
}
