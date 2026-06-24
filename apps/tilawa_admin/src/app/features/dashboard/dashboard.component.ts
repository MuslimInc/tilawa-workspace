import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UserService } from '../../core/services/user.service';
import { TranslatePipe } from '../../core/i18n/translate.pipe';
import { PageHeaderComponent } from '../../shared/components/page-header/page-header.component';
import { TilawaButtonComponent } from '../../shared/components/tilawa-button/tilawa-button.component';
import { TilawaCardComponent } from '../../shared/components/tilawa-card/tilawa-card.component';
import { TilawaEmptyStateComponent } from '../../shared/components/tilawa-empty-state/tilawa-empty-state.component';

@Component({
  selector: 'app-dashboard',
  imports: [
    CommonModule,
    TranslatePipe,
    PageHeaderComponent,
    TilawaButtonComponent,
    TilawaCardComponent,
    TilawaEmptyStateComponent,
  ],
  templateUrl: './dashboard.component.html',
})
export class DashboardComponent {
  private userService = inject(UserService);
  usersCount$ = this.userService.getUsersCount();
}
