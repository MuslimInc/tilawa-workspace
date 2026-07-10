import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-tilawa-card',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div [class]="cardClass">
      @if (title) {
        <div class="tilawa-card-header">
          <h2 class="tilawa-card-title">{{ title }}</h2>
          @if (subtitle) {
            <p class="tilawa-card-subtitle">{{ subtitle }}</p>
          }
        </div>
      }
      <div [class]="bodyClass">
        <ng-content />
      </div>
    </div>
  `,
  styles: `
    :host {
      display: block;
    }

    .tilawa-card {
      background-color: var(--tilawa-surface);
      border: 1px solid var(--tilawa-outline-variant);
      border-radius: var(--tilawa-radius-xl);
      box-shadow: var(--tilawa-shadow-card);
    }

    .tilawa-card-padded .tilawa-card-body {
      padding: var(--tilawa-space-4);
    }

    @media (min-width: 768px) {
      .tilawa-card-padded .tilawa-card-body {
        padding: var(--tilawa-space-6);
      }
    }

    .tilawa-card-header {
      padding: var(--tilawa-space-4);
      border-bottom: 1px solid var(--tilawa-outline-variant);
    }

    @media (min-width: 768px) {
      .tilawa-card-header {
        padding: var(--tilawa-space-5) var(--tilawa-space-6);
      }
    }

    .tilawa-card-title {
      margin: 0;
      font-size: 1.125rem;
      font-weight: 700;
      color: var(--tilawa-on-surface);
    }

    .tilawa-card-subtitle {
      margin: 0.25rem 0 0;
      font-size: 0.875rem;
      color: var(--tilawa-on-surface-variant);
    }
  `,
})
export class TilawaCardComponent {
  @Input() title = '';
  @Input() subtitle = '';
  @Input() padded = true;

  get cardClass(): string {
    return this.padded ? 'tilawa-card tilawa-card-padded' : 'tilawa-card';
  }

  get bodyClass(): string {
    return this.padded ? 'tilawa-card-body tilawa-card-padded' : 'tilawa-card-body';
  }
}
