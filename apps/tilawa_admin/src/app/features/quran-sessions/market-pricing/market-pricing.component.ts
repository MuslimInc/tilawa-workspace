import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';

import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { TilawaCardComponent } from '../../../shared/components/tilawa-card/tilawa-card.component';
import { TilawaButtonComponent } from '../../../shared/components/tilawa-button/tilawa-button.component';
import { TilawaLoadingStateComponent } from '../../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../../shared/components/tilawa-error-state/tilawa-error-state.component';
import { TilawaEmptyStateComponent } from '../../../shared/components/tilawa-empty-state/tilawa-empty-state.component';

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
    TilawaEmptyStateComponent
  ],
  templateUrl: './market-pricing.component.html',
  styleUrls: ['./market-pricing.component.scss']
})
export class MarketPricingComponent implements OnInit {
  public facade = inject(MarketPricingFacade);
  private fb = inject(FormBuilder);

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
    currencyCode: ['', Validators.required],
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

    if (this.pricingForm.dirty && !confirm('You have unsaved changes. Are you sure you want to switch markets?')) {
      // Revert the select if the user cancels
      const current = this.pricingForm.get('countryCode')?.value;
      selectEl.value = current;
      return;
    }
    this.facade.selectCountry(countryCode);
  }

  updateForm(market: MarketConfig) {
    this.pricingForm.patchValue({
      countryCode: market.countryCode,
      isEnabled: market.isEnabled,
      minSessionPrice: market.minSessionPrice,
      currencyCode: market.currencyCode
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
