import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { SessionReportsFacade } from '../../../core/application/facades/session-reports.facade';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { StatusLabelPipe } from '../../../core/i18n/status-label.pipe';

@Component({
  selector: 'app-session-report-detail',
  standalone: true,
  imports: [CommonModule, RouterLink, StatusChipComponent, TranslatePipe, StatusLabelPipe],
  templateUrl: './session-report-detail.component.html',
})
export class SessionReportDetailComponent implements OnInit {
  private readonly facade = inject(SessionReportsFacade);
  private readonly route = inject(ActivatedRoute);

  readonly detail = this.facade.detail;
  readonly loadState = this.facade.detailLoadState;
  readonly errorMessage = this.facade.detailErrorMessage;

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      void this.facade.loadDetail(id);
    }
  }
}
