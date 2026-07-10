import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';

@Component({
  selector: 'app-reject-reason-dialog',
  standalone: true,
  imports: [CommonModule, FormsModule, TranslatePipe],
  template: `
    @if (isOpen) {
      <div class="fixed inset-0 z-50 overflow-y-auto">
        <div class="flex min-h-screen items-center justify-center p-4">
          <div
            class="fixed inset-0 bg-gray-500/75 dark:bg-gray-900/80"
            (click)="cancel.emit()"
          ></div>
          <div class="relative w-full max-w-lg rounded-lg bg-white dark:bg-gray-800 p-6 shadow-xl">
            <h3 class="text-lg font-medium text-gray-900 dark:text-white">{{ title }}</h3>
            <p class="mt-2 text-sm text-gray-600 dark:text-gray-300">{{ message }}</p>
            <textarea
              rows="4"
              [(ngModel)]="reason"
              class="mt-4 block w-full rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-3 py-2 text-sm text-gray-900 dark:text-white"
              [placeholder]="'dialogs_enterReason' | t"
            ></textarea>
            <div class="mt-6 flex justify-end gap-3">
              <button
                type="button"
                (click)="cancel.emit()"
                class="rounded-md border border-gray-300 dark:border-gray-600 px-4 py-2 text-sm text-gray-700 dark:text-gray-200"
              >
                {{ 'common_cancel' | t }}
              </button>
              <button
                type="button"
                (click)="onSubmit()"
                [disabled]="(requireReason && !reason.trim()) || loading"
                class="rounded-md bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-500 disabled:opacity-50"
              >
                {{ confirmLabel }}
              </button>
            </div>
          </div>
        </div>
      </div>
    }
  `,
})
export class RejectReasonDialogComponent {
  @Input() isOpen = false;
  @Input() title = 'Provide a reason';
  @Input() message = 'This reason is stored for moderation records.';
  @Input() confirmLabel = 'Submit';
  @Input() loading = false;
  @Input() requireReason = true;

  @Output() submit = new EventEmitter<string>();
  @Output() cancel = new EventEmitter<void>();

  reason = '';

  onSubmit(): void {
    const trimmedReason = this.reason.trim();
    if (!this.requireReason || trimmedReason) {
      this.submit.emit(trimmedReason);
      this.reason = '';
    }
  }
}
