import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { TilawaButtonComponent } from '../tilawa-button/tilawa-button.component';

@Component({
  selector: 'app-tilawa-pagination',
  standalone: true,
  imports: [CommonModule, TranslatePipe, TilawaButtonComponent],
  template: `
    @if (canLoadMore) {
      <div class="tilawa-pagination">
        <app-tilawa-button
          type="button"
          variant="secondary"
          size="sm"
          [loading]="loading"
          (click)="loadMore.emit()"
        >
          {{ loadMoreLabel || ('common_loadMore' | t) }}
        </app-tilawa-button>
      </div>
    }
  `,
  styles: `
    .tilawa-pagination {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: var(--tilawa-space-3);
    }

    .tilawa-pagination-info {
      margin: 0;
      font-size: 0.8125rem;
      color: var(--tilawa-on-surface-variant);
    }
  `,
})
export class TilawaPaginationComponent {
  @Input() canLoadMore = false;
  @Input() loading = false;
  @Input() loadMoreLabel = '';

  @Output() readonly loadMore = new EventEmitter<void>();
}
