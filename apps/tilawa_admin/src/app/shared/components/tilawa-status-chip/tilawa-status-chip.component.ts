import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

import {
  resolveStatusVariant,
  StatusChipVariant,
} from '../../utils/status-chip.util';

@Component({
  selector: 'app-status-chip, app-tilawa-status-chip',
  standalone: true,
  imports: [CommonModule],
  template: `
    <span [class]="chipClass" [attr.data-variant]="variant">{{ label }}</span>
  `,
  styles: `
    span {
      display: inline-flex;
      align-items: center;
      border-radius: 9999px;
      padding: 0.125rem 0.625rem;
      font-size: 0.75rem;
      font-weight: 600;
      line-height: 1.25rem;
      white-space: nowrap;
    }

    .variant-success {
      background-color: var(--tilawa-success-container);
      color: var(--tilawa-on-success-container);
    }

    .variant-warning {
      background-color: var(--tilawa-warning-container);
      color: var(--tilawa-on-warning-container);
    }

    .variant-danger {
      background-color: var(--tilawa-error-container);
      color: var(--tilawa-on-error-container);
    }

    .variant-neutral {
      background-color: var(--tilawa-surface-high);
      color: var(--tilawa-on-surface-variant);
    }

    .variant-scholar {
      background-color: rgb(101 115 79 / 0.12);
      color: var(--tilawa-secondary);
    }

    .variant-info {
      background-color: rgb(139 94 60 / 0.1);
      color: var(--tilawa-primary);
    }
  `,
})
export class TilawaStatusChipComponent {
  @Input({ required: true }) label!: string;
  @Input() status = 'default';
  @Input() scholar = false;

  get variant(): StatusChipVariant {
    return resolveStatusVariant(this.status, { scholar: this.scholar });
  }

  get chipClass(): string {
    return `variant-${this.variant}`;
  }
}
