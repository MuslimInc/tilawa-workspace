import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { UserService } from '../../core/services/user.service';
import { NotificationModalComponent } from './components/notification-modal/notification-modal.component';
import { SendNotificationUseCase } from '../../core/domain/usecases/send-notification.usecase';
import { NotificationEntity, NotificationTargetType } from '../../core/domain/entities/notification.entity';
import { TranslatePipe } from '../../core/i18n/translate.pipe';
import { I18nService } from '../../core/i18n/i18n.service';

@Component({
  selector: 'app-users',
  standalone: true,
  imports: [CommonModule, FormsModule, NotificationModalComponent, TranslatePipe],
  templateUrl: './users.component.html',
  styleUrl: './users.css'
})
export class UsersComponent {
  private userService = inject(UserService);
  private sendNotificationUseCase = inject(SendNotificationUseCase);
  private readonly i18n = inject(I18nService);

  users$ = this.userService.getUsers();
  
  // Selection State
  selectedUserIds = new Set<string>();
  
  // Modal State
  isModalOpen = false;
  notificationTargetType: NotificationTargetType = 'all';
  notificationTargetSummary = '';

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

  toggleSelectAll(users: any[]) {
    if (this.isAllSelected(users.length)) {
      this.selectedUserIds.clear();
    } else {
      users.forEach(u => this.selectedUserIds.add(u.id));
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
    try {
      const entity = new NotificationEntity(
        null,
        payload.title,
        payload.body,
        this.notificationTargetType,
        Array.from(this.selectedUserIds),
        new Date(),
        payload.type,
        payload.data
      );
      
      await this.sendNotificationUseCase.execute(entity);
      
      this.isModalOpen = false;
      this.selectedUserIds.clear();
    } catch (error) {
      console.error('Failed to send notification:', error);
      alert(this.i18n.t('appUsers_sendFailed'));
    }
  }
}
