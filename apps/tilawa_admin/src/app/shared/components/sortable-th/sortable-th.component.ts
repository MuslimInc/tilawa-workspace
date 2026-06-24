import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';

import { SortRequest } from '../../../core/domain/entities/pagination.types';
import { nextSortForField } from '../../utils/sortable-column.util';

@Component({
  selector: 'app-sortable-th',
  standalone: true,
  imports: [CommonModule],
  template: `
    <th [class]="alignClass">
      <button
        type="button"
        class="group inline-flex items-center gap-1 font-semibold text-gray-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400"
        (click)="onClick()"
      >
        <span>{{ label }}</span>
        @if (isActive) {
          <span class="text-blue-600 dark:text-blue-400" aria-hidden="true">
            {{ sort.direction === 'asc' ? '↑' : '↓' }}
          </span>
        } @else {
          <span
            class="text-gray-300 group-hover:text-gray-400 dark:text-gray-600 dark:group-hover:text-gray-500"
            aria-hidden="true"
          >
            ↕
          </span>
        }
      </button>
    </th>
  `,
})
export class SortableThComponent {
  @Input({ required: true }) label!: string;
  @Input({ required: true }) field!: string;
  @Input({ required: true }) sort!: SortRequest;
  @Input() align: 'left' | 'right' = 'left';

  @Output() readonly sortChange = new EventEmitter<SortRequest>();

  get isActive(): boolean {
    return this.sort.field === this.field;
  }

  get alignClass(): string {
    const base = 'px-3 py-3 text-sm';
    return this.align === 'right'
      ? `${base} text-right`
      : `${base} text-left`;
  }

  onClick(): void {
    this.sortChange.emit(nextSortForField(this.sort, this.field));
  }
}
