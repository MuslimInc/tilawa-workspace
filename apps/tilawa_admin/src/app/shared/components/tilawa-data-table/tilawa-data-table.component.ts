import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-tilawa-data-table',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="tilawa-table-wrap">
      <table class="tilawa-table">
        <ng-content />
      </table>
    </div>
  `,
})
export class TilawaDataTableComponent {}
