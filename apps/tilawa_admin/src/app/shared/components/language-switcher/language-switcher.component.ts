import { Component, inject } from '@angular/core';

import { AppLanguage, I18nService } from '../../../core/i18n/i18n.service';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';

@Component({
  selector: 'app-language-switcher',
  standalone: true,
  imports: [TranslatePipe],
  template: `
    <div
      class="inline-flex items-center rounded-lg border border-[var(--tilawa-outline-variant)] bg-[var(--tilawa-surface-highest)] p-0.5 text-xs font-medium"
      role="group"
      [attr.aria-label]="'layout_language' | t"
    >
      <button
        type="button"
        class="rounded-md px-2.5 py-1 transition-colors"
        [class.bg-[var(--tilawa-surface)]]="language() === 'en'"
        [class.shadow-sm]="language() === 'en'"
        [class.text-[var(--tilawa-ink)]]="language() === 'en'"
        [class.text-[var(--tilawa-ink-muted)]]="language() !== 'en'"
        [class.hover:text-[var(--tilawa-ink)]]="language() !== 'en'"
        (click)="setLanguage('en')"
      >
        EN
      </button>
      <button
        type="button"
        class="rounded-md px-2.5 py-1 transition-colors"
        [class.bg-[var(--tilawa-surface)]]="language() === 'ar'"
        [class.shadow-sm]="language() === 'ar'"
        [class.text-[var(--tilawa-ink)]]="language() === 'ar'"
        [class.text-[var(--tilawa-ink-muted)]]="language() !== 'ar'"
        [class.hover:text-[var(--tilawa-ink)]]="language() !== 'ar'"
        (click)="setLanguage('ar')"
      >
        عربي
      </button>
    </div>
  `,
})
export class LanguageSwitcherComponent {
  private readonly i18n = inject(I18nService);

  readonly language = this.i18n.language;

  setLanguage(language: AppLanguage): void {
    void this.i18n.setLanguage(language);
  }
}
