import { Injectable, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

export type AppLanguage = 'en' | 'ar';

const STORAGE_KEY = 'tilawa-admin-lang';

type TranslationMap = Record<string, string>;

@Injectable({ providedIn: 'root' })
export class I18nService {
  private readonly http = inject(HttpClient);

  readonly language = signal<AppLanguage>(this.resolveInitialLanguage());
  readonly ready = signal(false);

  private translations: TranslationMap = {};

  async initialize(): Promise<void> {
    await this.load(this.language());
    this.applyDocumentAttributes(this.language());
  }

  async setLanguage(language: AppLanguage): Promise<void> {
    if (language === this.language()) {
      return;
    }

    this.language.set(language);
    localStorage.setItem(STORAGE_KEY, language);
    await this.load(language);
    this.applyDocumentAttributes(language);
  }

  t(key: string, params?: Record<string, string>): string {
    const value = this.translations[key] ?? key;
    if (!params) {
      return value;
    }

    return Object.entries(params).reduce(
      (text, [name, replacement]) =>
        text.replaceAll(`{${name}}`, replacement).replaceAll(`{{${name}}}`, replacement),
      value,
    );
  }

  isRtl(): boolean {
    return this.language() === 'ar';
  }

  private async load(language: AppLanguage): Promise<void> {
    this.ready.set(false);
    try {
      const arb = await firstValueFrom(
        this.http.get<Record<string, unknown>>(`/l10n/app_${language}.arb`),
      );
      this.translations = this.parseArb(arb);
    } catch (error) {
      console.error(`Failed to load l10n for ${language}`, error);
      this.translations = {};
    }
    this.ready.set(true);
  }

  private parseArb(arb: Record<string, unknown>): TranslationMap {
    const messages: TranslationMap = {};

    for (const [key, value] of Object.entries(arb)) {
      if (key.startsWith('@') || typeof value !== 'string') {
        continue;
      }
      messages[key] = value;
    }

    return messages;
  }

  private resolveInitialLanguage(): AppLanguage {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored === 'en' || stored === 'ar') {
      return stored;
    }

    const browserLanguage = navigator.language.toLowerCase();
    return browserLanguage.startsWith('ar') ? 'ar' : 'en';
  }

  private applyDocumentAttributes(language: AppLanguage): void {
    const root = document.documentElement;
    root.lang = language;
    root.dir = language === 'ar' ? 'rtl' : 'ltr';
  }
}
