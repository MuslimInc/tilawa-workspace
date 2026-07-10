import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';

import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { TilawaCardComponent } from '../../../shared/components/tilawa-card/tilawa-card.component';
import { TilawaButtonComponent } from '../../../shared/components/tilawa-button/tilawa-button.component';
import { TilawaLoadingStateComponent } from '../../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../../shared/components/tilawa-error-state/tilawa-error-state.component';
import { TilawaEmptyStateComponent } from '../../../shared/components/tilawa-empty-state/tilawa-empty-state.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { I18nService } from '../../../core/i18n/i18n.service';

import { MarketPricingFacade, MarketConfig, MarketCity } from './market-pricing.facade';

@Component({
  selector: 'app-market-pricing',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    PageHeaderComponent,
    TilawaCardComponent,
    TilawaButtonComponent,
    TilawaLoadingStateComponent,
    TilawaErrorStateComponent,
    TilawaEmptyStateComponent,
    TranslatePipe
  ],
  templateUrl: './market-pricing.component.html',
  styleUrls: ['./market-pricing.component.scss']
})
export class MarketPricingComponent implements OnInit {
  public facade = inject(MarketPricingFacade);
  private fb = inject(FormBuilder);
  private i18n = inject(I18nService);

  markets$ = this.facade.markets$;
  selectedCountryCode$ = this.facade.selectedCountryCode$;
  loading$ = this.facade.loading$;
  saving$ = this.facade.saving$;
  error$ = this.facade.error$;
  successMessage$ = this.facade.successMessage$;

  pricingForm: FormGroup = this.fb.group({
    countryCode: ['', Validators.required],
    isEnabled: [true],
    minSessionPrice: [0, [Validators.required, Validators.min(0)]],
    currencyCode: ['EGP', Validators.required],
    studentBookingEnabled: [true],
    teacherDiscoveryEnabled: [true],
    paymentProviderEnabled: [false],
    manualPaymentEnabled: [false],
    bookingMode: ['requiresTutorApproval'],
    joinWindowLeadMs: [0, Validators.min(0)],
    tutorApprovalSlaMs: [0, Validators.min(0)],
    minBookingNoticeMs: [0, Validators.min(0)],
    maxConcurrentUpcomingPerStudent: [3, Validators.min(1)],
    sessionMode: ['videoOnly'],
    genderMatchingEnabled: [false],
    supportWhatsappNumber: ['+201060099009'],
    instapayHandle: [''],
    instapayPaymentLink: [''],
    vodafoneCashNumber: [''],
    recipientMaskedName: [''],
    cities: this.fb.array([])
  });

  currentMarketConfig: MarketConfig | null = null;

  ngOnInit() {
    this.facade.loadMarkets();
    
    // Subscribe to selected country changes to update the form
    this.selectedCountryCode$.subscribe(countryCode => {
      if (countryCode) {
        this.markets$.subscribe(markets => {
          const market = markets.find(m => m.countryCode === countryCode);
          if (market) {
            this.currentMarketConfig = market;
            this.updateForm(market);
          }
        }).unsubscribe();
      }
    });
  }

  get citiesFormArray() {
    return this.pricingForm.get('cities') as FormArray;
  }

  onMarketSelect(event: Event) {
    const selectEl = event.target as HTMLSelectElement;
    const countryCode = selectEl.value;

    if (this.pricingForm.dirty && !confirm(this.i18n.t('marketPricing_unsavedChangesWarning'))) {
      // Revert the select if the user cancels
      const current = this.pricingForm.get('countryCode')?.value;
      selectEl.value = current;
      return;
    }
    this.facade.selectCountry(countryCode);
  }

  onPaymentToggle(event: Event) {
    const inputEl = event.target as HTMLInputElement;
    if (inputEl.checked) {
      if (!confirm(this.i18n.t('marketPricing_paymentToggleWarning'))) {
        inputEl.checked = false;
        this.pricingForm.get('paymentProviderEnabled')?.setValue(false, { emitEvent: false });
      }
    }
  }

  updateForm(market: MarketConfig) {
    this.pricingForm.patchValue({
      countryCode: market.countryCode,
      isEnabled: market.isEnabled,
      minSessionPrice: market.minSessionPrice,
      currencyCode: market.currencyCode,
      studentBookingEnabled: market.studentBookingEnabled ?? true,
      teacherDiscoveryEnabled: market.teacherDiscoveryEnabled ?? true,
      paymentProviderEnabled: market.paymentProviderEnabled ?? false,
      manualPaymentEnabled: market.manualPaymentEnabled ?? false,
      bookingMode: market.bookingMode ?? 'requiresTutorApproval',
      joinWindowLeadMs: market.joinWindowLeadMs ?? 0,
      tutorApprovalSlaMs: market.tutorApprovalSlaMs ?? 0,
      minBookingNoticeMs: market.minBookingNoticeMs ?? 0,
      maxConcurrentUpcomingPerStudent: market.maxConcurrentUpcomingPerStudent ?? 3,
      sessionMode: market.sessionMode ?? 'videoOnly',
      genderMatchingEnabled: market.genderMatchingEnabled ?? false,
      supportWhatsappNumber: market.supportWhatsappNumber ?? '+201060099009',
      instapayHandle: market.instapayHandle ?? '',
      instapayPaymentLink: market.instapayPaymentLink ?? '',
      vodafoneCashNumber: market.vodafoneCashNumber ?? '',
      recipientMaskedName: market.recipientMaskedName ?? ''
    }, { emitEvent: false });

    this.citiesFormArray.clear();
    
    if (market.cities) {
      market.cities.forEach(city => {
        this.citiesFormArray.push(this.fb.group({
          cityId: [city.cityId],
          cityName: [city.cityName],
          cityNameEn: [city.cityNameEn],
          isEnabled: [city.isEnabled],
          minSessionPrice: [city.minSessionPrice, [Validators.min(0)]]
        }));
      });
    }
    this.pricingForm.markAsPristine();
  }

  async save() {
    if (this.pricingForm.invalid || !this.currentMarketConfig) {
      return;
    }

    const formValue = this.pricingForm.value;
    
    const configToSave: MarketConfig = {
      countryCode: this.currentMarketConfig.countryCode,
      isEnabled: formValue.isEnabled,
      minSessionPrice: formValue.minSessionPrice,
      currencyCode: formValue.currencyCode,
      studentBookingEnabled: formValue.studentBookingEnabled,
      teacherDiscoveryEnabled: formValue.teacherDiscoveryEnabled,
      paymentProviderEnabled: formValue.paymentProviderEnabled,
      manualPaymentEnabled: formValue.manualPaymentEnabled,
      bookingMode: formValue.bookingMode,
      joinWindowLeadMs: formValue.joinWindowLeadMs,
      tutorApprovalSlaMs: formValue.tutorApprovalSlaMs,
      minBookingNoticeMs: formValue.minBookingNoticeMs,
      maxConcurrentUpcomingPerStudent: formValue.maxConcurrentUpcomingPerStudent,
      sessionMode: formValue.sessionMode,
      genderMatchingEnabled: formValue.genderMatchingEnabled,
      teacherWhitelist: this.currentMarketConfig.teacherWhitelist ?? null,
      supportWhatsappNumber: formValue.supportWhatsappNumber || null,
      instapayHandle: formValue.instapayHandle || null,
      instapayPaymentLink: formValue.instapayPaymentLink || null,
      vodafoneCashNumber: formValue.vodafoneCashNumber || null,
      recipientMaskedName: formValue.recipientMaskedName || null,
      cities: formValue.cities.map((c: any) => ({
        cityId: c.cityId,
        cityName: c.cityName,
        cityNameEn: c.cityNameEn,
        isEnabled: c.isEnabled,
        minSessionPrice: c.minSessionPrice !== null && c.minSessionPrice !== '' ? Number(c.minSessionPrice) : undefined
      }))
    };

    try {
      await this.facade.saveMarketConfig(configToSave);
      this.pricingForm.markAsPristine();
    } catch (e) {
      // Error is handled by facade
    }
  }
}
