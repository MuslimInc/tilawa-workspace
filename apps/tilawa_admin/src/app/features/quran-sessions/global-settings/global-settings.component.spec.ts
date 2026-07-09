import { describe, expect, it, vi } from 'vitest';
import { signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { I18nService } from '../../../core/i18n/i18n.service';
import { GlobalSettingsFacade } from './global-settings.facade';
import { GlobalSettingsComponent } from './global-settings.component';

function makeFacade() {
  return {
    loading$: of(false),
    saving$: of(false),
    error$: of(null),
    successMessage$: of(null),
    getConfig: vi.fn(() =>
      of({
        quranSessionsEnabled: true,
        studentEntryEnabled: true,
        bookingEnabled: true,
        enableForAllMarkets: false,
        enabledMarketCodes: ['EG'],
        teacherApplicationEnabled: false,
        teacherApplicationEntryEnabled: false,
        homeTeacherApplicationCardEnabled: false,
        teacherApplicationDiscoverability: 'none',
        sessionMode: 'videoOnly',
        bookingMode: 'requiresTutorApproval',
        defaultJoinWindowLeadMs: 300000,
        defaultTutorApprovalSlaMs: 3600000,
        defaultMinBookingNoticeMs: 1800000,
        defaultMaxUpcomingPerStudent: 3,
        childAgeThreshold: 16,
      }),
    ),
    saveConfig: vi.fn().mockResolvedValue(undefined),
  };
}

describe('GlobalSettingsComponent', () => {
  let facade: ReturnType<typeof makeFacade>;
  let fixture: ComponentFixture<GlobalSettingsComponent>;

  beforeEach(async () => {
    facade = makeFacade();

    await TestBed.configureTestingModule({
      imports: [GlobalSettingsComponent],
      providers: [
        { provide: GlobalSettingsFacade, useValue: facade },
        {
          provide: I18nService,
          useValue: {
            language: signal('en'),
            ready: signal(true),
            t: (key: string) => key,
          },
        },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(GlobalSettingsComponent);
    fixture.detectChanges();
  });

  it('retains the loaded child age threshold when saving an unrelated change', async () => {
    const component = fixture.componentInstance;
    const childAgeThreshold = component.settingsForm.get('childAgeThreshold');

    expect(childAgeThreshold?.value).toBe(16);

    component.settingsForm.patchValue({ bookingEnabled: false });
    await component.save();

    expect(facade.saveConfig).toHaveBeenCalledWith(
      expect.objectContaining({
        bookingEnabled: false,
        childAgeThreshold: 16,
      }),
    );
  });

  it('does not submit a non-positive child age threshold', async () => {
    const component = fixture.componentInstance;

    component.settingsForm.patchValue({ childAgeThreshold: 0 });
    await component.save();

    expect(facade.saveConfig).not.toHaveBeenCalled();
  });
});
