import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';

import { SortRequest } from '../../../core/domain/entities/pagination.types';
import { nextSortForField } from '../../utils/sortable-column.util';

@Component({
  selector: 'app-sortable-th',
  standalone: true,
  imports: [CommonModule],
  template: `
    <th [class]="alignClass" scope="col">
      <button
        type="button"
        class="tilawa-sort-btn"
        [attr.aria-sort]="ariaSort"
        (click)="onClick()"
      >
        <span>{{ label }}</span>
        <span class="tilawa-sort-icon" aria-hidden="true">{{ sortIcon }}</span>
      </button>
    </th>
  `,
  styles: `
    :host {
      display: contents;
    }

    th {
      vertical-align: middle;
    }

    .tilawa-sort-btn {
      display: inline-flex;
      align-items: center;
      gap: var(--tilawa-space-2);
      font-weight: 600;
      line-height: 1.25;
      color: var(--tilawa-on-surface);
      background: none;
      border: none;
      padding: 0;
      cursor: pointer;
      font-size: inherit;
      white-space: nowrap;
    }

    .tilawa-sort-btn:hover {
      color: var(--tilawa-primary);
    }

    .tilawa-sort-btn:focus-visible {
      outline: 2px solid var(--tilawa-primary);
      outline-offset: 2px;
      border-radius: 2px;
    }

    .tilawa-sort-icon {
      display: inline-flex;
      align-items: center;
      flex-shrink: 0;
      font-size: 0.75rem;
      line-height: 1;
      color: var(--tilawa-ink-ash);
    }

    .tilawa-sort-btn:hover .tilawa-sort-icon,
    .tilawa-sort-btn[aria-sort]:not([aria-sort='none']) .tilawa-sort-icon {
      color: var(--tilawa-primary);
    }
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

  get ariaSort(): 'ascending' | 'descending' | 'none' {
    if (!this.isActive) {
      return 'none';
    }
    return this.sort.direction === 'asc' ? 'ascending' : 'descending';
  }

  get sortIcon(): string {
    if (!this.isActive) {
      return '↕';
    }
    return this.sort.direction === 'asc' ? '↑' : '↓';
  }

  get alignClass(): string {
    return this.align === 'right' ? 'text-end' : '';
  }

  onClick(): void {
    this.sortChange.emit(nextSortForField(this.sort, this.field));
  }
}
