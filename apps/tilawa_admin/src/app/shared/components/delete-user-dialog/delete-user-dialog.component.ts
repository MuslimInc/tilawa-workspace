import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

import { TranslatePipe } from '../../../core/i18n/translate.pipe';

export interface DeleteUserDialogSubmit {
  readonly reason: string;
  readonly confirmEmail: string;
}

@Component({
  selector: 'app-delete-user-dialog',
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
          <div
            class="relative w-full max-w-lg rounded-lg bg-white dark:bg-gray-800 p-6 shadow-xl"
          >
            <h3 class="text-lg font-medium text-red-700 dark:text-red-400">
              {{ title }}
            </h3>
            <p class="mt-2 text-sm text-gray-600 dark:text-gray-300">
              {{ message }}
            </p>
            @if (targetEmail) {
              <p class="mt-2 text-sm font-medium text-gray-900 dark:text-white">
                {{ 'userDeletion_targetEmail' | t }}: {{ targetEmail }}
              </p>
            }
            <p class="mt-3 rounded-md bg-amber-50 dark:bg-amber-950/40 p-3 text-sm text-amber-900 dark:text-amber-200">
              {{ warning }}
            </p>
            <label class="mt-4 block text-sm font-medium text-gray-700 dark:text-gray-200">
              {{ confirmLabel }}
            </label>
            <input
              type="text"
              [(ngModel)]="confirmText"
              class="mt-1 block w-full rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-3 py-2 text-sm text-gray-900 dark:text-white"
              [placeholder]="confirmPlaceholder"
              autocomplete="off"
            />
            <label class="mt-4 block text-sm font-medium text-gray-700 dark:text-gray-200">
              {{ 'dialogs_enterReason' | t }}
            </label>
            <textarea
              rows="4"
              [(ngModel)]="reason"
              class="mt-1 block w-full rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-3 py-2 text-sm text-gray-900 dark:text-white"
              [placeholder]="'userDeletion_reasonPlaceholder' | t"
            ></textarea>
            @if (errorMessage) {
              <p
                class="mt-4 rounded-md bg-red-50 dark:bg-red-950/40 p-3 text-sm text-red-800 dark:text-red-200"
                role="alert"
              >
                {{ errorMessage }}
              </p>
            }
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
                [disabled]="!canSubmit || loading"
                class="rounded-md bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-500 disabled:opacity-50"
              >
                {{ submitLabel }}
              </button>
            </div>
          </div>
        </div>
      </div>
    }
  `,
})
export class DeleteUserDialogComponent {
  @Input() isOpen = false;
  @Input() title = 'Delete account';
  @Input() message = '';
  @Input() warning = '';
  @Input() targetEmail: string | null = null;
  @Input() confirmLabel = 'Confirm';
  @Input() confirmPlaceholder = '';
  @Input() submitLabel = 'Delete account';
  @Input() loading = false;
  @Input() errorMessage: string | null = null;

  @Output() submit = new EventEmitter<DeleteUserDialogSubmit>();
  @Output() cancel = new EventEmitter<void>();

  confirmText = '';
  reason = '';

  get canSubmit(): boolean {
    const trimmedConfirm = this.confirmText.trim();
    const trimmedReason = this.reason.trim();
    if (trimmedReason.length < 10) {
      return false;
    }
    if (trimmedConfirm.toLowerCase() === 'delete') {
      return true;
    }
    if (this.targetEmail) {
      return trimmedConfirm.toLowerCase() === this.targetEmail.trim().toLowerCase();
    }
    return trimmedConfirm.length > 0;
  }

  onSubmit(): void {
    if (!this.canSubmit) {
      return;
    }
    this.submit.emit({
      reason: this.reason.trim(),
      confirmEmail: this.confirmText.trim(),
    });
    this.confirmText = '';
    this.reason = '';
  }
}

