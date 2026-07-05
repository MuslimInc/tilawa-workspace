import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';

import { DuplicateAccountsFacade } from '../../../core/application/facades/duplicate-accounts.facade';
import { DuplicateAuthAccount } from '../../../core/domain/entities/duplicate-auth-account.entity';
import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';
import { TilawaButtonComponent } from '../../../shared/components/tilawa-button/tilawa-button.component';
import { TilawaDataTableComponent } from '../../../shared/components/tilawa-data-table/tilawa-data-table.component';
import { TilawaErrorStateComponent } from '../../../shared/components/tilawa-error-state/tilawa-error-state.component';
import { TilawaLoadingStateComponent } from '../../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { StatusLabelPipe } from '../../../core/i18n/status-label.pipe';

@Component({
  selector: 'app-duplicate-accounts',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    PageHeaderComponent,
    StatusChipComponent,
    TilawaButtonComponent,
    TilawaDataTableComponent,
    TilawaErrorStateComponent,
    TilawaLoadingStateComponent,
    TranslatePipe,
    StatusLabelPipe,
  ],
  templateUrl: './duplicate-accounts.component.html',
})
export class DuplicateAccountsComponent implements OnInit {
  private readonly facade = inject(DuplicateAccountsFacade);
  private readonly route = inject(ActivatedRoute);

  readonly loadState = this.facade.loadState;
  readonly errorMessage = this.facade.errorMessage;
  readonly result = this.facade.result;
  readonly isActionLoading = this.facade.isActionLoading;
  readonly actionErrorMessage = this.facade.actionErrorMessage;

  emailQuery = '';
  keepUserId = signal<string | null>(null);
  selectedDeleteIds = signal<Set<string>>(new Set());
  reason = '';
  confirmEmail = '';
  confirmOpen = false;
  forceDeleteGoogleAccount = false;

  readonly accounts = computed(() => this.result()?.accounts ?? []);
  readonly normalizedEmail = computed(() => this.result()?.email ?? '');
  readonly deletePreview = computed(() => [...this.selectedDeleteIds()]);
  readonly keepPreview = computed(() => this.keepUserId());
  readonly deletingGoogleAccounts = computed(() =>
    this.accounts().filter(
      (account) => account.hasGoogleProvider && this.selectedDeleteIds().has(account.uid),
    ),
  );
  readonly requiresForceForGoogle = computed(() => this.deletingGoogleAccounts().length > 0);
  readonly canUseKeepGoogle = computed(() => this.facade.applyKeepGooglePlan() != null);
  readonly requiresManualSelection = computed(() => {
    const accounts = this.accounts();
    return this.facade.googleAccountCount(accounts) > 1;
  });

  ngOnInit(): void {
    const email = this.route.snapshot.queryParamMap.get('email')?.trim();
    if (!email) {
      return;
    }
    this.emailQuery = email;
    void this.search();
  }

  async search(): Promise<void> {
    this.keepUserId.set(null);
    this.selectedDeleteIds.set(new Set());
    await this.facade.lookupByEmail(this.emailQuery);
    const plan = this.facade.applyKeepGooglePlan();
    if (plan) {
      this.keepUserId.set(plan.keepUserId);
      this.selectedDeleteIds.set(new Set(plan.deleteUserIds));
    } else if (this.accounts().length === 1) {
      this.keepUserId.set(this.accounts()[0]?.uid ?? null);
    }
  }

  selectKeep(uid: string): void {
    this.keepUserId.set(uid);
    const next = new Set(this.selectedDeleteIds());
    next.delete(uid);
    this.selectedDeleteIds.set(next);
  }

  toggleDelete(uid: string, checked: boolean): void {
    if (uid === this.keepUserId()) return;
    const next = new Set(this.selectedDeleteIds());
    if (checked) {
      next.add(uid);
    } else {
      next.delete(uid);
    }
    this.selectedDeleteIds.set(next);
  }

  isDeleteSelected(uid: string): boolean {
    return this.selectedDeleteIds().has(uid);
  }

  applyKeepGooglePlan(): void {
    const plan = this.facade.applyKeepGooglePlan();
    if (!plan) return;
    this.keepUserId.set(plan.keepUserId);
    this.selectedDeleteIds.set(new Set(plan.deleteUserIds));
  }

  openConfirm(): void {
    this.confirmOpen = true;
  }

  closeConfirm(): void {
    this.confirmOpen = false;
  }

  get canOpenConfirm(): boolean {
    const keep = this.keepUserId();
    const deletes = this.deletePreview();
    return !!keep && deletes.length > 0 && !deletes.includes(keep);
  }

  get confirmEmailMatches(): boolean {
    const typed = this.confirmEmail.trim().toLowerCase();
    return typed === this.normalizedEmail().toLowerCase() || typed === 'delete';
  }

  async submitDeletion(): Promise<void> {
    const keep = this.keepUserId();
    if (!keep) return;
    try {
      await this.facade.requestDeletion({
        email: this.normalizedEmail(),
        reason: this.reason.trim(),
        confirmEmail: this.confirmEmail.trim(),
        keepUserId: keep,
        deleteUserIds: this.deletePreview(),
        forceDeleteGoogleAccount: this.forceDeleteGoogleAccount,
      });
      this.confirmOpen = false;
      this.reason = '';
      this.confirmEmail = '';
    } catch {
      // surfaced via actionErrorMessage
    }
  }

  accountStatusLabel(account: DuplicateAuthAccount): string {
    return (
      account.deletionStateStatus ??
      account.firestoreProfileStatus ??
      account.firestoreAccountStatus ??
      'unknown'
    );
  }

  formatTimestamp(value: string | null): string {
    if (!value) return '—';
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? value : date.toLocaleString();
  }
}
