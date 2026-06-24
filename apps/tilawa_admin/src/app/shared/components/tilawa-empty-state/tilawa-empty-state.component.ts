import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-tilawa-empty-state',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="tilawa-empty" role="status">
      <div class="tilawa-empty-icon" aria-hidden="true">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="1.5"
            d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          />
        </svg>
      </div>
      <h3 class="tilawa-empty-title">{{ title }}</h3>
      @if (description) {
        <p class="tilawa-empty-desc">{{ description }}</p>
      }
      <div class="tilawa-empty-actions">
        <ng-content />
      </div>
    </div>
  `,
  styles: `
    .tilawa-empty {
      text-align: center;
      padding: 3rem 1.5rem;
    }

    .tilawa-empty-icon {
      margin: 0 auto;
      width: 3rem;
      height: 3rem;
      color: var(--tilawa-ink-ash);
    }

    .tilawa-empty-icon svg {
      width: 100%;
      height: 100%;
    }

    .tilawa-empty-title {
      margin: 0.75rem 0 0;
      font-size: 0.9375rem;
      font-weight: 600;
      color: var(--tilawa-on-surface);
    }

    .tilawa-empty-desc {
      margin: 0.375rem 0 0;
      font-size: 0.875rem;
      color: var(--tilawa-on-surface-variant);
    }

    .tilawa-empty-actions {
      margin-top: 1rem;
      display: flex;
      justify-content: center;
      gap: 0.75rem;
    }
  `,
})
export class TilawaEmptyStateComponent {
  @Input({ required: true }) title!: string;
  @Input() description = '';
}
