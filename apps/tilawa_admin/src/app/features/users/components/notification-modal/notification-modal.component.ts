import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TranslatePipe } from '../../../../core/i18n/translate.pipe';

@Component({
  selector: 'app-notification-modal',
  standalone: true,
  imports: [CommonModule, FormsModule, TranslatePipe],
  template: `
    @if (isOpen) {
      <div class="fixed inset-0 z-50 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
        <!-- Backdrop -->
        <div class="flex min-h-screen items-center justify-center p-4 text-center sm:p-0">
          <div class="fixed inset-0 bg-gray-500/75 transition-opacity dark:bg-gray-900/80" aria-hidden="true" (click)="close.emit()"></div>

          <!-- Modal Panel -->
          <div class="relative transform overflow-hidden rounded-lg bg-white dark:bg-gray-800 px-4 pt-5 pb-4 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg sm:p-6">
            <div>
              <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-blue-100 dark:bg-blue-900/30">
                <svg class="h-6 w-6 text-blue-600 dark:text-blue-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                </svg>
              </div>
              <div class="mt-3 text-center sm:mt-5">
                <h3 class="text-lg leading-6 font-medium text-gray-900 dark:text-white" id="modal-title">
                  {{ 'notifications_title' | t }}
                </h3>
                <div class="mt-2 text-sm text-gray-500 dark:text-gray-400">
                  {{ 'notifications_targetPrefix' | t }} <span class="font-bold text-gray-900 dark:text-white">{{ targetSummary }}</span>.
                </div>
              </div>
            </div>

            <div class="mt-5 space-y-4">
              <div>
                <label for="title" class="block text-sm font-medium text-gray-700 dark:text-gray-300">{{ 'notifications_notificationTitle' | t }}</label>
                <div class="mt-1">
                  <input type="text" id="title" [(ngModel)]="notificationTitle" class="p-3 shadow-sm focus:ring-blue-500 focus:border-blue-500 block w-full sm:text-sm border-gray-300 rounded-md dark:bg-gray-700 dark:border-gray-600 dark:text-white dark:placeholder-gray-400" [placeholder]="'notifications_titlePlaceholder' | t">
                </div>
              </div>

              <div>
                <label for="action" class="block text-sm font-medium text-gray-700 dark:text-gray-300">{{ 'notifications_deepLinkAction' | t }}</label>
                <select id="action" [(ngModel)]="actionType" class="mt-1 p-3 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md dark:bg-gray-700 dark:border-gray-600 dark:text-white">
                  <option value="home">{{ 'notifications_homeScreen' | t }}</option>
                  <option value="reciter">{{ 'notifications_reciterDetails' | t }}</option>
                  <option value="athkar">{{ 'notifications_athkarScreen' | t }}</option>
                  <option value="quran">{{ 'notifications_quranReader' | t }}</option>
                  <option value="settings">{{ 'notifications_settings' | t }}</option>
                </select>
              </div>

              @if (actionType === 'reciter' || actionType === 'quran') {
                <div>
                  <label for="actionData" class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                    {{ actionType === 'reciter' ? ('notifications_reciterId' | t) : ('notifications_surahNumber' | t) }}
                  </label>
                  <div class="mt-1">
                    <input type="text" id="actionData" [(ngModel)]="actionData" class="p-3 shadow-sm focus:ring-blue-500 focus:border-blue-500 block w-full sm:text-sm border-gray-300 rounded-md dark:bg-gray-700 dark:border-gray-600 dark:text-white dark:placeholder-gray-400" [placeholder]="actionType === 'reciter' ? ('notifications_reciterIdPlaceholder' | t) : ('notifications_surahNumberPlaceholder' | t)">
                  </div>
                </div>
              }

              <div>
                <label for="body" class="block text-sm font-medium text-gray-700 dark:text-gray-300">{{ 'notifications_messageBody' | t }}</label>
                <div class="mt-1">
                  <textarea id="body" rows="3" [(ngModel)]="notificationBody" class="p-3 shadow-sm focus:ring-blue-500 focus:border-blue-500 block w-full sm:text-sm border border-gray-300 rounded-md dark:bg-gray-700 dark:border-gray-600 dark:text-white dark:placeholder-gray-400" [placeholder]="'notifications_bodyPlaceholder' | t"></textarea>
                </div>
              </div>
            </div>

            <div class="mt-5 sm:mt-6 sm:flex sm:flex-row-reverse">
              <button type="button" 
                (click)="onSend()"
                [disabled]="!notificationTitle.trim() || !notificationBody.trim() || ((actionType === 'reciter' || actionType === 'quran') && !actionData.trim())"
                class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:ml-3 sm:w-auto sm:text-sm disabled:opacity-50 disabled:cursor-not-allowed">
                {{ 'notifications_send' | t }}
              </button>
              <button type="button" (click)="close.emit()" class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:mt-0 sm:w-auto sm:text-sm dark:bg-gray-700 dark:text-gray-200 dark:border-gray-600 dark:hover:bg-gray-600">
                {{ 'common_cancel' | t }}
              </button>
            </div>
          </div>
        </div>
      </div>
    }
  `
})
export class NotificationModalComponent {
  @Input() isOpen = false;
  @Input() targetSummary = '';
  
  @Output() send = new EventEmitter<{ title: string; body: string; type: string; data?: string }>();
  @Output() close = new EventEmitter<void>();

  notificationTitle = '';
  notificationBody = '';
  actionType = 'home';
  actionData = '';

  onSend() {
    if (this.notificationTitle.trim() && this.notificationBody.trim()) {
      const payload: { title: string; body: string; type: string; data?: string } = {
        title: this.notificationTitle,
        body: this.notificationBody,
        type: this.actionType
      };
      
      if (this.actionData.trim()) {
        payload.data = this.actionData.trim();
      }

      this.send.emit(payload);
      this.close.emit();
      this.notificationTitle = '';
      this.notificationBody = '';
      this.actionType = 'home';
      this.actionData = '';
    }
  }
}
