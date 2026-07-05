import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { NotificationModalComponent } from './components/notification-modal/notification-modal.component';
import { DeleteUserDialogComponent } from '../../shared/components/delete-user-dialog/delete-user-dialog.component';
import { SendNotificationUseCase } from '../../core/domain/usecases/send-notification.usecase';
import {
  NotificationEntity,
  NotificationTargetType,
} from '../../core/domain/entities/notification.entity';
import { TranslatePipe } from '../../core/i18n/translate.pipe';
import { I18nService } from '../../core/i18n/i18n.service';
import { TilawaUsersFacade } from '../../core/application/facades/tilawa-users.facade';
import { StatusChipComponent } from '../../shared/components/status-chip/status-chip.component';
import { SortableThComponent } from '../../shared/components/sortable-th/sortable-th.component';
import { PageHeaderComponent } from '../../shared/components/page-header/page-header.component';
import { TilawaButtonComponent } from '../../shared/components/tilawa-button/tilawa-button.component';
import { TilawaDataTableComponent } from '../../shared/components/tilawa-data-table/tilawa-data-table.component';
import { TilawaLoadingStateComponent } from '../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../shared/components/tilawa-error-state/tilawa-error-state.component';
import { TilawaEmptyStateComponent } from '../../shared/components/tilawa-empty-state/tilawa-empty-state.component';
import { TilawaPaginationComponent } from '../../shared/components/tilawa-pagination/tilawa-pagination.component';
import { TilawaAvatarComponent } from '../../shared/components/tilawa-avatar/tilawa-avatar.component';
import { SortRequest } from '../../core/domain/entities/pagination.types';

@Component({
  selector: 'app-users',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterLink,
    NotificationModalComponent,
    DeleteUserDialogComponent,
    TranslatePipe,
    StatusChipComponent,
    SortableThComponent,
    PageHeaderComponent,
    TilawaButtonComponent,
    TilawaDataTableComponent,
    TilawaLoadingStateComponent,
    TilawaErrorStateComponent,
    TilawaEmptyStateComponent,
    TilawaPaginationComponent,
    TilawaAvatarComponent,
  ],
  templateUrl: './users.component.html',
})
export class UsersComponent implements OnInit {
  private readonly usersFacade = inject(TilawaUsersFacade);
  private readonly sendNotificationUseCase = inject(SendNotificationUseCase);
  private readonly i18n = inject(I18nService);

  readonly users = this.usersFacade.items;
  readonly loadState = this.usersFacade.listLoadState;
  readonly errorMessage = this.usersFacade.listErrorMessage;
  readonly canLoadMore = this.usersFacade.canLoadMore;
  readonly sort = this.usersFacade.sort;
  readonly isActionLoading = this.usersFacade.isActionLoading;
  readonly actionErrorMessage = this.usersFacade.actionErrorMessage;
  readonly hasDuplicateEmailsInList = computed(() =>
    this.users().some((user) => user.hasDuplicateEmail),
  );

  selectedUserIds = new Set<string>();

  isModalOpen = false;
  deleteOpen = false;
  pendingUserId = '';
  pendingUserEmail: string | null = null;
  readonly notifyLoading = signal(false);
  notificationTargetType: NotificationTargetType = 'all';
  notificationTargetSummary = '';

  ngOnInit(): void {
    void this.reload();
  }

  reload(): Promise<void> {
    return this.usersFacade.loadList({});
  }

  loadMore(): Promise<void> {
    return this.usersFacade.loadMore({});
  }

  onSortChange(sort: SortRequest): void {
    void this.usersFacade.changeSort({}, sort);
  }

  toggleSelection(userId: string) {
    if (this.selectedUserIds.has(userId)) {
      this.selectedUserIds.delete(userId);
    } else {
      this.selectedUserIds.add(userId);
    }
  }

  isAllSelected(totalUsers: number): boolean {
    return totalUsers > 0 && this.selectedUserIds.size === totalUsers;
  }

  toggleSelectAll(users: { id: string }[]) {
    if (this.isAllSelected(users.length)) {
      this.selectedUserIds.clear();
    } else {
      users.forEach((u) => this.selectedUserIds.add(u.id));
    }
  }

  openNotificationModal(type: NotificationTargetType, singleUserId?: string) {
    this.notificationTargetType = type;

    if (type === 'all') {
      this.notificationTargetSummary = this.i18n.t('notifications_targetAll');
      this.selectedUserIds.clear();
    } else if (type === 'single' && singleUserId) {
      this.notificationTargetSummary = this.i18n.t('notifications_targetSingle');
      this.selectedUserIds.clear();
      this.selectedUserIds.add(singleUserId);
    } else if (type === 'selected') {
      this.notificationTargetSummary = this.i18n.t('notifications_targetSelected', {
        count: String(this.selectedUserIds.size),
      });
    }

    this.isModalOpen = true;
  }

  async onSendNotification(payload: { title: string; body: string; type: string; data?: string }) {
    this.notifyLoading.set(true);
    try {
      const entity = new NotificationEntity(
        null,
        payload.title,
        payload.body,
        this.notificationTargetType,
        Array.from(this.selectedUserIds),
        new Date(),
        payload.type,
        payload.data,
      );

      await this.sendNotificationUseCase.execute(entity);

      this.isModalOpen = false;
      this.selectedUserIds.clear();
    } catch (error) {
      console.error('Failed to send notification:', error);
      alert(this.i18n.t('appUsers_sendFailed'));
    } finally {
      this.notifyLoading.set(false);
    }
  }

  openDelete(userId: string, email: string): void {
    this.usersFacade.clearActionError();
    this.pendingUserId = userId;
    this.pendingUserEmail = email && email !== this.i18n.t('appUsers_notAvailable') ? email : null;
    this.deleteOpen = true;
  }

  onDeleteCancel(): void {
    this.usersFacade.clearActionError();
    this.deleteOpen = false;
  }

  async onDelete(payload: { reason: string; confirmEmail: string }): Promise<void> {
    try {
      await this.usersFacade.requestUserDeletion(
        this.pendingUserId,
        payload.reason,
        payload.confirmEmail,
      );
      this.deleteOpen = false;
      await this.reload();
    } catch {
      // actionErrorMessage surfaced in delete dialog
    }
  }
}
