import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-page-header, app-tilawa-page-header',
  standalone: true,
  imports: [CommonModule],
  template: `
    <header class="tilawa-page-header">
      <div class="tilawa-page-header-text">
        <h1 class="tilawa-page-title">{{ title }}</h1>
        @if (subtitle) {
          <p class="tilawa-page-subtitle">{{ subtitle }}</p>
        }
      </div>
      @if (hasActions) {
        <div class="tilawa-page-actions">
          <ng-content select="[actions]" />
        </div>
      }
    </header>
  `,
  styles: `
    .tilawa-page-header {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 1rem;
    }

    .tilawa-page-title {
      margin: 0;
      font-size: 1.5rem;
      font-weight: 700;
      line-height: 1.3;
      color: var(--tilawa-on-surface);
    }

    .tilawa-page-subtitle {
      margin: 0.375rem 0 0;
      font-size: 0.875rem;
      color: var(--tilawa-on-surface-variant);
    }

    .tilawa-page-actions {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 0.5rem;
    }
  `,
})
export class TilawaPageHeaderComponent {
  @Input({ required: true }) title!: string;
  @Input() subtitle = '';
  @Input() hasActions = true;
}
