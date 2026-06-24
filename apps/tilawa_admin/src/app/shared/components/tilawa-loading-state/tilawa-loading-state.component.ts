import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-tilawa-loading-state',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="tilawa-loading" role="status" [attr.aria-label]="message">
      <span class="tilawa-loading-spinner" aria-hidden="true"></span>
      <p class="tilawa-loading-text">{{ message }}</p>
    </div>
  `,
  styles: `
    .tilawa-loading {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 0.75rem;
      padding: 2rem 1rem;
    }

    .tilawa-loading-spinner {
      width: 2rem;
      height: 2rem;
      border: 3px solid var(--tilawa-outline-variant);
      border-top-color: var(--tilawa-primary);
      border-radius: 50%;
      animation: spin 0.7s linear infinite;
    }

    .tilawa-loading-text {
      margin: 0;
      font-size: 0.875rem;
      color: var(--tilawa-on-surface-variant);
    }

    @keyframes spin {
      to {
        transform: rotate(360deg);
      }
    }
  `,
})
export class TilawaLoadingStateComponent {
  @Input() message = 'Loading…';
}
