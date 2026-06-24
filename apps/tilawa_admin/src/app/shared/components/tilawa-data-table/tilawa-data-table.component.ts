import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

export type TilawaTablePinMode = 'none' | 'leading' | 'select-leading';
export type TilawaTableLeadingSize = 'compact' | 'default' | 'wide';

@Component({
  selector: 'app-tilawa-data-table',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="tilawa-table-wrap">
      <table
        class="tilawa-table"
        [class.tilawa-table--pinned]="pinMode !== 'none'"
        [style.--tilawa-pin-lead-width]="leadWidth"
      >
        @if (pinMode !== 'none') {
          <colgroup>
            <col [style.width]="leadWidth" />
          </colgroup>
        }
        <ng-content />
      </table>
    </div>
  `,
})
export class TilawaDataTableComponent {
  @Input() pinMode: TilawaTablePinMode = 'none';
  @Input() leadingSize: TilawaTableLeadingSize = 'default';

  get leadWidth(): string {
    if (this.pinMode === 'select-leading') {
      return '9rem';
    }

    switch (this.leadingSize) {
      case 'compact':
        return '8.75rem';
      case 'wide':
        return '15rem';
      default:
        return '13rem';
    }
  }
}
