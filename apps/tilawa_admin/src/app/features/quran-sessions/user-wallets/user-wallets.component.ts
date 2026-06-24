import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';

import { UserWalletsFacade } from '../../../core/application/facades/user-wallets.facade';
import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';
import { TilawaButtonComponent } from '../../../shared/components/tilawa-button/tilawa-button.component';
import { TilawaCardComponent } from '../../../shared/components/tilawa-card/tilawa-card.component';
import { TilawaDataTableComponent } from '../../../shared/components/tilawa-data-table/tilawa-data-table.component';
import { TilawaLoadingStateComponent } from '../../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../../shared/components/tilawa-error-state/tilawa-error-state.component';
import { TilawaEmptyStateComponent } from '../../../shared/components/tilawa-empty-state/tilawa-empty-state.component';
import { TilawaPaginationComponent } from '../../../shared/components/tilawa-pagination/tilawa-pagination.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { StatusLabelPipe } from '../../../core/i18n/status-label.pipe';

@Component({
  selector: 'app-user-wallets',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    PageHeaderComponent,
    StatusChipComponent,
    TilawaButtonComponent,
    TilawaCardComponent,
    TilawaDataTableComponent,
    TilawaLoadingStateComponent,
    TilawaErrorStateComponent,
    TilawaEmptyStateComponent,
    TilawaPaginationComponent,
    TranslatePipe,
    StatusLabelPipe,
  ],
  templateUrl: './user-wallets.component.html',
})
export class UserWalletsComponent implements OnInit {
  private readonly facade = inject(UserWalletsFacade);
  private readonly route = inject(ActivatedRoute);

  readonly detail = this.facade.detail;
  readonly loadState = this.facade.detailLoadState;
  readonly errorMessage = this.facade.detailErrorMessage;
  readonly canLoadMoreTransactions = this.facade.canLoadMoreTransactions;

  userIdQuery = '';

  ngOnInit(): void {
    const routeUserId = this.route.snapshot.paramMap.get('userId');
    if (routeUserId) {
      this.userIdQuery = routeUserId;
      void this.facade.loadForUser(routeUserId);
    }
  }

  loadWallet(): Promise<void> {
    return this.facade.loadForUser(this.userIdQuery);
  }

  loadMoreTransactions(): Promise<void> {
    return this.facade.loadMoreTransactions();
  }
}
