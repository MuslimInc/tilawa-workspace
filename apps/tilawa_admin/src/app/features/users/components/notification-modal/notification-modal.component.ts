import { Component, EventEmitter, Input, OnChanges, Output, SimpleChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TranslatePipe } from '../../../../core/i18n/translate.pipe';
import { TilawaButtonComponent } from '../../../../shared/components/tilawa-button/tilawa-button.component';

@Component({
  selector: 'app-notification-modal',
  standalone: true,
  imports: [CommonModule, FormsModule, TranslatePipe, TilawaButtonComponent],
  template: `
    @if (isOpen) {
      <div class="fixed inset-0 z-50 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
        <div class="flex min-h-screen items-center justify-center p-4 text-center sm:p-0">
          <div class="fixed inset-0 bg-black/40 transition-opacity" aria-hidden="true" (click)="onClose()"></div>

          <div class="relative w-full max-w-lg transform overflow-hidden rounded-[var(--tilawa-radius-xl)] border border-[var(--tilawa-outline-variant)] bg-[var(--tilawa-surface)] px-4 pt-5 pb-4 text-left shadow-[var(--tilawa-shadow-card)] transition-all sm:my-8 sm:p-6">
            <div class="text-center">
              <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-[var(--tilawa-surface-high)]">
                <svg class="h-6 w-6 text-[var(--tilawa-primary)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                </svg>
              </div>
              <div class="mt-3 sm:mt-5">
                <h3 class="text-lg font-semibold text-[var(--tilawa-on-surface)]" id="modal-title">
                  {{ 'notifications_title' | t }}
                </h3>
                <p class="mt-2 text-sm text-[var(--tilawa-on-surface-variant)]">
                  {{ 'notifications_targetPrefix' | t }}
                  <span class="font-semibold text-[var(--tilawa-on-surface)]">{{ targetSummary }}</span>.
                </p>
              </div>
            </div>

            <div class="mt-5 space-y-4">
              <div>
                <label for="title" class="tilawa-detail-label">{{ 'notifications_notificationTitle' | t }}</label>
                <input
                  type="text"
                  id="title"
                  [(ngModel)]="notificationTitle"
                  class="tilawa-field mt-1 w-full"
                  [placeholder]="'notifications_titlePlaceholder' | t"
                  [disabled]="loading"
                />
              </div>

              <div>
                <label for="action" class="tilawa-detail-label">{{ 'notifications_deepLinkAction' | t }}</label>
                <select id="action" [(ngModel)]="actionType" class="tilawa-field mt-1 w-full" [disabled]="loading">
                  <option value="home">{{ 'notifications_homeScreen' | t }}</option>
                  <option value="reciter">{{ 'notifications_reciterDetails' | t }}</option>
                  <option value="athkar">{{ 'notifications_athkarScreen' | t }}</option>
                  <option value="quran">{{ 'notifications_quranReader' | t }}</option>
                  <option value="settings">{{ 'notifications_settings' | t }}</option>
                </select>
              </div>

              @if (actionType === 'reciter' || actionType === 'quran') {
                <div>
                  <label for="actionData" class="tilawa-detail-label">
                    {{ actionType === 'reciter' ? ('notifications_reciterId' | t) : ('notifications_surahNumber' | t) }}
                  </label>
                  <input
                    type="text"
                    id="actionData"
                    [(ngModel)]="actionData"
                    class="tilawa-field mt-1 w-full"
                    [placeholder]="actionType === 'reciter' ? ('notifications_reciterIdPlaceholder' | t) : ('notifications_surahNumberPlaceholder' | t)"
                    [disabled]="loading"
                  />
                </div>
              }

              <div>
                <label for="body" class="tilawa-detail-label">{{ 'notifications_messageBody' | t }}</label>
                <textarea
                  id="body"
                  rows="3"
                  [(ngModel)]="notificationBody"
                  class="tilawa-field mt-1 w-full"
                  [placeholder]="'notifications_bodyPlaceholder' | t"
                  [disabled]="loading"
                ></textarea>
              </div>
            </div>

            <div class="mt-5 flex flex-col-reverse gap-2 sm:mt-6 sm:flex-row sm:justify-end">
              <app-tilawa-button type="button" variant="secondary" [disabled]="loading" (click)="onClose()">
                {{ 'common_cancel' | t }}
              </app-tilawa-button>
              <app-tilawa-button
                type="button"
                variant="primary"
                [loading]="loading"
                [disabled]="!canSend"
                (click)="onSend()"
              >
                {{ 'notifications_send' | t }}
              </app-tilawa-button>
            </div>
          </div>
        </div>
      </div>
    }
  `,
})
export class NotificationModalComponent implements OnChanges {
  @Input() isOpen = false;
  @Input() targetSummary = '';
  @Input() loading = false;

  @Output() send = new EventEmitter<{ title: string; body: string; type: string; data?: string }>();
  @Output() close = new EventEmitter<void>();

  notificationTitle = '';
  notificationBody = '';
  actionType = 'home';
  actionData = '';

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['isOpen'] && !this.isOpen && !this.loading) {
      this.resetForm();
    }
  }

  get canSend(): boolean {
    if (this.loading) {
      return false;
    }
    if (!this.notificationTitle.trim() || !this.notificationBody.trim()) {
      return false;
    }
    if (
      (this.actionType === 'reciter' || this.actionType === 'quran') &&
      !this.actionData.trim()
    ) {
      return false;
    }
    return true;
  }

  onSend(): void {
    if (!this.canSend) {
      return;
    }

    const payload: { title: string; body: string; type: string; data?: string } = {
      title: this.notificationTitle.trim(),
      body: this.notificationBody.trim(),
      type: this.actionType,
    };

    if (this.actionData.trim()) {
      payload.data = this.actionData.trim();
    }

    this.send.emit(payload);
  }

  onClose(): void {
    if (this.loading) {
      return;
    }
    this.resetForm();
    this.close.emit();
  }

  private resetForm(): void {
    this.notificationTitle = '';
    this.notificationBody = '';
    this.actionType = 'home';
    this.actionData = '';
  }
}
