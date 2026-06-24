import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { TilawaButtonComponent } from '../tilawa-button/tilawa-button.component';

@Component({
  selector: 'app-confirm-dialog',
  standalone: true,
  imports: [CommonModule, TranslatePipe, TilawaButtonComponent],
  template: `
    @if (isOpen) {
      <div class="fixed inset-0 z-50 overflow-y-auto" role="dialog" aria-modal="true">
        <div class="flex min-h-screen items-center justify-center p-4">
          <div
            class="fixed inset-0 bg-black/40"
            (click)="cancel.emit()"
            aria-hidden="true"
          ></div>
          <div
            class="relative w-full max-w-md rounded-[var(--tilawa-radius-lg)] bg-[var(--tilawa-surface)] p-6 shadow-[var(--tilawa-shadow-md)] border border-[var(--tilawa-outline-variant)]"
          >
            <h3 class="text-lg font-semibold text-[var(--tilawa-on-surface)]">
              {{ title }}
            </h3>
            <p class="mt-2 text-sm text-[var(--tilawa-on-surface-variant)]">
              {{ message }}
            </p>
            <div class="mt-6 flex justify-end gap-3">
              <app-tilawa-button variant="secondary" size="sm" (click)="cancel.emit()">
                {{ 'common_cancel' | t }}
              </app-tilawa-button>
              <app-tilawa-button
                [variant]="destructive ? 'danger' : 'primary'"
                size="sm"
                [loading]="loading"
                (click)="confirm.emit()"
              >
                {{ confirmLabel }}
              </app-tilawa-button>
            </div>
          </div>
        </div>
      </div>
    }
  `,
})
export class ConfirmDialogComponent {
  @Input() isOpen = false;
  @Input() title = 'Confirm';
  @Input() message = 'Are you sure?';
  @Input() confirmLabel = 'Confirm';
  @Input() loading = false;
  @Input() destructive = false;

  @Output() confirm = new EventEmitter<void>();
  @Output() cancel = new EventEmitter<void>();
}
