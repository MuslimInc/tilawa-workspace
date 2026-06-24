import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';

import { TilawaButtonComponent } from '../tilawa-button/tilawa-button.component';

@Component({
  selector: 'app-tilawa-error-state',
  standalone: true,
  imports: [CommonModule, TilawaButtonComponent],
  template: `
    <div class="tilawa-error" role="alert">
      <p class="tilawa-error-message">{{ message }}</p>
      @if (showRetry) {
        <app-tilawa-button variant="secondary" size="sm" (click)="retry.emit()">
          {{ retryLabel }}
        </app-tilawa-button>
      }
    </div>
  `,
  styles: `
    .tilawa-error {
      text-align: center;
      padding: 2rem 1rem;
    }

    .tilawa-error-message {
      margin: 0 0 1rem;
      font-size: 0.875rem;
      color: var(--tilawa-error);
    }
  `,
})
export class TilawaErrorStateComponent {
  @Input({ required: true }) message!: string;
  @Input() showRetry = false;
  @Input() retryLabel = 'Try again';

  @Output() readonly retry = new EventEmitter<void>();
}
