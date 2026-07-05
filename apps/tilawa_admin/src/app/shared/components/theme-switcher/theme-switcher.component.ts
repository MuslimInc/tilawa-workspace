import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ThemeService } from '../../../core/services/theme.service';

@Component({
  selector: 'app-theme-switcher',
  standalone: true,
  imports: [CommonModule],
  template: `
    <button
      (click)="toggleTheme()"
      class="inline-flex h-8 w-8 items-center justify-center rounded-lg border border-[var(--tilawa-outline-variant)] bg-[var(--tilawa-surface)] text-[var(--tilawa-on-surface-variant)] hover:bg-[var(--tilawa-surface-high)] hover:text-[var(--tilawa-on-surface)] transition-colors"
      [attr.aria-label]="isDark() ? 'Switch to light mode' : 'Switch to dark mode'"
    >
      <!-- Sun icon for dark mode (click to switch to light) -->
      <svg
        *ngIf="isDark()"
        xmlns="http://www.w3.org/2000/svg"
        width="16"
        height="16"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
      >
        <circle cx="12" cy="12" r="4"></circle>
        <path d="M12 2v2"></path>
        <path d="M12 20v2"></path>
        <path d="m4.93 4.93 1.41 1.41"></path>
        <path d="m17.66 17.66 1.41 1.41"></path>
        <path d="M2 12h2"></path>
        <path d="M20 12h2"></path>
        <path d="m6.34 17.66-1.41 1.41"></path>
        <path d="m19.07 4.93-1.41 1.41"></path>
      </svg>
      <!-- Moon icon for light mode (click to switch to dark) -->
      <svg
        *ngIf="!isDark()"
        xmlns="http://www.w3.org/2000/svg"
        width="16"
        height="16"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
      >
        <path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"></path>
      </svg>
    </button>
  `,
  styles: [],
})
export class ThemeSwitcherComponent {
  private themeService = inject(ThemeService);

  isDark() {
    return this.themeService.theme() === 'dark';
  }

  toggleTheme() {
    this.themeService.toggleTheme();
  }
}
