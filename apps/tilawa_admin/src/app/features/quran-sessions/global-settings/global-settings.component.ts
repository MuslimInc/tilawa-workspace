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
    enableForAllMarkets: [false],
    // Comma-separated ISO codes in the form; normalized to string[] on save.
    enabledMarketCodesText: [''],
    teacherApplicationEnabled: [false],
    teacherApplicationEntryEnabled: [false],
    homeTeacherApplicationCardEnabled: [false],
    teacherApplicationDiscoverability: ['none', Validators.required],
    sessionMode: ['videoOnly', Validators.required],
    bookingMode: ['requiresTutorApproval', Validators.required],
    defaultJoinWindowLeadMs: [0, [Validators.required, Validators.min(0)]],
    defaultTutorApprovalSlaMs: [0, [Validators.required, Validators.min(0)]],
    defaultMinBookingNoticeMs: [0, [Validators.required, Validators.min(0)]],
    defaultMaxUpcomingPerStudent: [0, [Validators.required, Validators.min(1)]]
  });

  ngOnInit() {
    this.facade.getConfig().subscribe(config => {
      if (config) {
        this.settingsForm.patchValue({
          ...config,
          enabledMarketCodesText: (config.enabledMarketCodes ?? []).join(', ')
        });
        this.settingsForm.markAsPristine();
      }
    });
  }

  /** Parses the comma/space separated codes input into normalized ISO codes. */
  private parseMarketCodes(raw: string): string[] {
    const seen = new Set<string>();
    for (const part of (raw ?? '').split(/[\s,]+/)) {
      const code = part.trim().toUpperCase();
      if (code.length > 0) seen.add(code);
    }
    return [...seen];
  }

  async save() {
    if (this.settingsForm.invalid) return;

    const { enabledMarketCodesText, ...rest } = this.settingsForm.value;
    const payload: PlatformConfig = {
      ...rest,
      enabledMarketCodes: this.parseMarketCodes(enabledMarketCodesText)
    };

    try {
      await this.facade.saveConfig(payload);
      this.settingsForm.markAsPristine();
    } catch (e) {
      // Facade handles the error
    }
  }
}
