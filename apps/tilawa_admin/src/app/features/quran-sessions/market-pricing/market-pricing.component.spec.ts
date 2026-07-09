import { describe, expect, it, vi } from 'vitest';
import { signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { I18nService } from '../../../core/i18n/i18n.service';
import { MarketPricingComponent } from './market-pricing.component';
import { MarketPricingFacade } from './market-pricing.facade';

function makeFacade() {
  const market = {
    countryCode: 'EG',
    isEnabled: true,
    minSessionPrice: 100,
    currencyCode: 'EGP',
    studentBookingEnabled: true,
    teacherDiscoveryEnabled: true,
    paymentProviderEnabled: false,
    manualPaymentEnabled: false,
    bookingMode: 'requiresTutorApproval',
    joinWindowLeadMs: 300000,
    tutorApprovalSlaMs: 3600000,
    minBookingNoticeMs: 1800000,
    maxConcurrentUpcomingPerStudent: 3,
    sessionMode: 'videoOnly',
    genderMatchingEnabled: false,
    teacherWhitelist: null,
    cities: [],
  };

  return {
    markets$: of([market]),
    selectedCountryCode$: of('EG'),
    loading$: of(false),
    saving$: of(false),
    error$: of(null),
    successMessage$: of(null),
    loadMarkets: vi.fn(),
    selectCountry: vi.fn(),
    saveMarketConfig: vi.fn().mockResolvedValue(undefined),
  };
}

describe('MarketPricingComponent', () => {
  let facade: ReturnType<typeof makeFacade>;
  let fixture: ComponentFixture<MarketPricingComponent>;

  beforeEach(async () => {
    facade = makeFacade();

    await TestBed.configureTestingModule({
      imports: [MarketPricingComponent],
      providers: [
        { provide: MarketPricingFacade, useValue: facade },
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

    fixture = TestBed.createComponent(MarketPricingComponent);
    fixture.detectChanges();
  });

  it('does not render a market-level session-mode control', () => {
    expect(
      fixture.nativeElement.querySelector('[formControlName="sessionMode"]'),
    ).toBeNull();
  });

  it('does not submit a market-level session mode', async () => {
    await fixture.componentInstance.save();

    expect(facade.saveMarketConfig).toHaveBeenCalledWith(
      expect.not.objectContaining({ sessionMode: expect.anything() }),
    );
  });
});
