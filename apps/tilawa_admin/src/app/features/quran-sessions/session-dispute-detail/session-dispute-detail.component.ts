import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { SessionDisputesFacade } from '../../../core/application/facades/session-disputes.facade';
import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';
import { TilawaCardComponent } from '../../../shared/components/tilawa-card/tilawa-card.component';
import { TilawaLoadingStateComponent } from '../../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../../shared/components/tilawa-error-state/tilawa-error-state.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { StatusLabelPipe } from '../../../core/i18n/status-label.pipe';

@Component({
  selector: 'app-session-dispute-detail',
  standalone: true,
  imports: [
    CommonModule,
    RouterLink,
    PageHeaderComponent,
    StatusChipComponent,
    TilawaCardComponent,
    TilawaLoadingStateComponent,
    TilawaErrorStateComponent,
    TranslatePipe,
    StatusLabelPipe,
  ],
  templateUrl: './session-dispute-detail.component.html',
})
export class SessionDisputeDetailComponent implements OnInit {
  private readonly facade = inject(SessionDisputesFacade);
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
