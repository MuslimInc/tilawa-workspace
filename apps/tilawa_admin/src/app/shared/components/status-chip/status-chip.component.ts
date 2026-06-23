import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-status-chip',
  standalone: true,
  imports: [CommonModule],
  template: `
    <span [class]="chipClass">{{ label }}</span>
  `,
})
export class StatusChipComponent {
  @Input({ required: true }) label!: string;
  @Input() status = 'default';

  get chipClass(): string {
    const base =
      'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium';
    switch (this.status) {
      case 'pending':
        return `${base} bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-200`;
      case 'approved':
      case 'active':
      case 'verified':
        return `${base} bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-200`;
      case 'rejected':
      case 'blocked':
      case 'revoked':
        return `${base} bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-200`;
      case 'suspended':
      case 'inactive':
        return `${base} bg-orange-100 text-orange-800 dark:bg-orange-900/40 dark:text-orange-200`;
      case 'draft':
        return `${base} bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200`;
      default:
        return `${base} bg-blue-100 text-blue-800 dark:bg-blue-900/40 dark:text-blue-200`;
    }
  }
}
