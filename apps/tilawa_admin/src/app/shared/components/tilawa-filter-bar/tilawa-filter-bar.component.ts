import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { TilawaButtonComponent } from '../tilawa-button/tilawa-button.component';

@Component({
  selector: 'app-tilawa-filter-bar',
  standalone: true,
  imports: [CommonModule, TranslatePipe, TilawaButtonComponent],
  template: `
    <div class="tilawa-filter-bar">
      <div class="tilawa-filter-fields">
        <ng-content />
      </div>
      @if (showApply) {
        <div class="tilawa-filter-actions">
          <app-tilawa-button
            type="button"
            variant="primary"
            size="sm"
            [loading]="applying"
            (click)="apply.emit()"
          >
            {{ applyLabel || ('common_applyFilters' | t) }}
          </app-tilawa-button>
        </div>
      }
    </div>
  `,
  styles: `
    .tilawa-filter-bar {
      display: flex;
      flex-direction: column;
      gap: var(--tilawa-space-5);
    }

    .tilawa-filter-fields {
      display: grid;
      grid-template-columns: repeat(1, minmax(0, 1fr));
      gap: var(--tilawa-space-4);
    }

    @media (min-width: 640px) {
      .tilawa-filter-fields {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }
    }

    @media (min-width: 1024px) {
      .tilawa-filter-fields {
        grid-template-columns: repeat(4, minmax(0, 1fr));
      }
    }

    .tilawa-filter-actions {
      display: flex;
      align-items: center;
      gap: var(--tilawa-space-3);
    }
  `,
})
export class TilawaFilterBarComponent {
  @Input() showApply = true;
  @Input() applying = false;
  @Input() applyLabel = '';

  @Output() readonly apply = new EventEmitter<void>();
}
