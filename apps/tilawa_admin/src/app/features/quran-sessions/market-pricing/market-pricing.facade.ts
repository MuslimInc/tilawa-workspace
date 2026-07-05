import { Injectable, inject } from '@angular/core';
import { Firestore, collection, doc, collectionData } from '@angular/fire/firestore';
import { Functions, httpsCallable } from '@angular/fire/functions';
import { BehaviorSubject, Observable, from, combineLatest } from 'rxjs';
import { map, switchMap, catchError, tap } from 'rxjs/operators';

export interface MarketCity {
  cityId: string;
  cityName: string;
  cityNameEn?: string;
  isEnabled: boolean;
  minSessionPrice?: number;
  sortOrder: number;
}

export interface MarketConfig {
  countryCode: string;
  isEnabled: boolean;
  minSessionPrice: number;
  currencyCode: string;
  cities?: MarketCity[];
}

interface MarketPricingState {
  markets: MarketConfig[];
  selectedCountryCode: string | null;
  loading: boolean;
  saving: boolean;
  error: string | null;
  successMessage: string | null;
}

@Injectable({
  providedIn: 'root'
})
export class MarketPricingFacade {
  private firestore = inject(Firestore);
  private functions = inject(Functions);

  private state = new BehaviorSubject<MarketPricingState>({
    markets: [],
    selectedCountryCode: null,
    loading: false,
    saving: false,
    error: null,
    successMessage: null,
  });

  markets$ = this.state.asObservable().pipe(map(s => s.markets));
  selectedCountryCode$ = this.state.asObservable().pipe(map(s => s.selectedCountryCode));
  loading$ = this.state.asObservable().pipe(map(s => s.loading));
  saving$ = this.state.asObservable().pipe(map(s => s.saving));
  error$ = this.state.asObservable().pipe(map(s => s.error));
  successMessage$ = this.state.asObservable().pipe(map(s => s.successMessage));

  loadMarkets() {
    this.updateState({ loading: true, error: null, successMessage: null });
    
    const marketsRef = collection(this.firestore, 'quran_session_market_configs');
    collectionData(marketsRef, { idField: 'countryCode' }).pipe(
      switchMap((marketsData: any[]) => {
        // Fetch cities subcollection for each market
        const marketsWithCities$ = marketsData.map(market => {
          const citiesRef = collection(this.firestore, `quran_session_market_configs/${market.countryCode}/cities`);
          return collectionData(citiesRef, { idField: 'cityId' }).pipe(
            map((citiesData: any[]) => {
              const cities: MarketCity[] = citiesData.map(c => ({
                cityId: c.cityId,
                cityName: c.cityName,
                cityNameEn: c.cityNameEn,
                isEnabled: c.isEnabled ?? true,
                minSessionPrice: c.minSessionPrice,
                sortOrder: c.sortOrder ?? 0,
              })).sort((a, b) => a.sortOrder - b.sortOrder);
              
              return {
                countryCode: market.countryCode,
                isEnabled: market.isEnabled ?? true,
                minSessionPrice: market.minSessionPrice ?? 0,
                currencyCode: market.currencyCode ?? 'USD',
                cities
              } as MarketConfig;
            })
          );
        });
        
        return marketsWithCities$.length ? combineLatest(marketsWithCities$) : from([[]]);
      }),
      tap(markets => {
        const sorted = [...markets].sort((a, b) => a.countryCode.localeCompare(b.countryCode));
        this.updateState({ 
          markets: sorted, 
          loading: false,
          selectedCountryCode: this.state.value.selectedCountryCode 
            ? this.state.value.selectedCountryCode
            : sorted.find(m => m.countryCode === 'EG') 
              ? 'EG' 
              : sorted.length > 0 ? sorted[0].countryCode : null
        });
      }),
      catchError(err => {
        this.updateState({ loading: false, error: err.message });
        throw err;
      })
    ).subscribe();
  }

  selectCountry(countryCode: string) {
    this.updateState({ selectedCountryCode: countryCode, error: null, successMessage: null });
  }

  async saveMarketConfig(config: MarketConfig) {
    this.updateState({ saving: true, error: null, successMessage: null });
    try {
      const callable = httpsCallable(this.functions, 'updateMarketPricingConfig');
      const payload = {
        countryCode: config.countryCode,
        isEnabled: config.isEnabled,
        minSessionPrice: config.minSessionPrice,
        currencyCode: config.currencyCode,
        cities: config.cities?.map(c => ({
          cityId: c.cityId,
          isEnabled: c.isEnabled,
          minSessionPrice: c.minSessionPrice
        })) || []
      };
      
      await callable(payload);
      this.updateState({ saving: false, successMessage: 'marketPricing_updateSuccess' });
      
      // Clear success message after 3 seconds
      setTimeout(() => {
        if (this.state.value.successMessage) {
          this.updateState({ successMessage: null });
        }
      }, 3000);
    } catch (error: any) {
      console.error('Failed to save market config', error);
      this.updateState({ saving: false, error: error.message });
      throw error;
    }
  }

  private updateState(changes: Partial<MarketPricingState>) {
    this.state.next({ ...this.state.value, ...changes });
  }
}
