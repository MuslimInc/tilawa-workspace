import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-page-header',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="sm:flex sm:items-center sm:justify-between">
      <div class="sm:flex-auto">
        <h1 class="text-xl font-semibold leading-6 text-gray-900 dark:text-white">{{ title }}</h1>
        @if (subtitle) {
          <p class="mt-2 text-sm text-gray-700 dark:text-gray-300">{{ subtitle }}</p>
        }
      </div>
      <div class="mt-4 sm:mt-0">
        <ng-content select="[actions]"></ng-content>
      </div>
    </div>
  `,
})
export class PageHeaderComponent {
  @Input({ required: true }) title!: string;
  @Input() subtitle = '';
}
