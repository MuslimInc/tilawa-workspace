import { Component, inject } from '@angular/core';

import { AppLanguage, I18nService } from '../../../core/i18n/i18n.service';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';

@Component({
  selector: 'app-language-switcher',
  standalone: true,
  imports: [TranslatePipe],
  template: `
    <div
      class="inline-flex items-center rounded-lg border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900 p-0.5 text-xs font-medium"
      role="group"
      [attr.aria-label]="'layout_language' | t"
    >
      <button
        type="button"
        class="rounded-md px-2.5 py-1 transition-colors"
        [class.bg-white]="language() === 'en'"
        [class.dark:bg-gray-800]="language() === 'en'"
        [class.shadow-sm]="language() === 'en'"
        [class.text-gray-900]="language() === 'en'"
        [class.dark:text-white]="language() === 'en'"
        [class.text-gray-500]="language() !== 'en'"
        (click)="setLanguage('en')"
      >
        EN
      </button>
      <button
        type="button"
        class="rounded-md px-2.5 py-1 transition-colors"
        [class.bg-white]="language() === 'ar'"
        [class.dark:bg-gray-800]="language() === 'ar'"
        [class.shadow-sm]="language() === 'ar'"
        [class.text-gray-900]="language() === 'ar'"
        [class.dark:text-white]="language() === 'ar'"
        [class.text-gray-500]="language() !== 'ar'"
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
