import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { TilawaFilterBarComponent } from '../../../shared/components/tilawa-filter-bar/tilawa-filter-bar.component';
import { TilawaDataTableComponent } from '../../../shared/components/tilawa-data-table/tilawa-data-table.component';
import { TilawaLoadingStateComponent } from '../../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../../shared/components/tilawa-error-state/tilawa-error-state.component';
import { TilawaEmptyStateComponent } from '../../../shared/components/tilawa-empty-state/tilawa-empty-state.component';
import { TilawaButtonComponent } from '../../../shared/components/tilawa-button/tilawa-button.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { StatusLabelPipe } from '../../../core/i18n/status-label.pipe';
import { I18nService } from '../../../core/i18n/i18n.service';

import {
  DedicationRecord,
  DedicationsRepository,
} from '../shared/dedications.repository';
import {
  DEDICATION_STATUS_OPTIONS,
  DedicationStatus,
} from '../shared/relation.options';

@Component({
  selector: 'app-sadaqah-jariyah-list',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    PageHeaderComponent,
    TilawaFilterBarComponent,
    TilawaDataTableComponent,
    TilawaLoadingStateComponent,
    TilawaErrorStateComponent,
    TilawaEmptyStateComponent,
    TilawaButtonComponent,
    StatusChipComponent,
    TranslatePipe,
    StatusLabelPipe,
  ],
  templateUrl: './sadaqah-jariyah-list.component.html',
})
export class SadaqahJariyahListComponent implements OnInit {
  private readonly repository = inject(DedicationsRepository);
  private readonly i18n = inject(I18nService);

  readonly items = signal<DedicationRecord[]>([]);
  readonly filteredItems = signal<DedicationRecord[]>([]);
  readonly loading = signal(true);
  readonly errorMessage = signal<string | null>(null);

  statusFilter = '';
  searchQuery = '';

  readonly statusOptions = DEDICATION_STATUS_OPTIONS;

  ngOnInit(): void {
    void this.reload();
  }

  async reload(): Promise<void> {
    this.loading.set(true);
    this.errorMessage.set(null);
    try {
      const status = this.statusFilter as DedicationStatus | '';
      const rows = await this.repository.listDedications(status);
      this.items.set(rows);
      this.applyClientFilters();
    } catch (error: unknown) {
      const message =
        error instanceof Error ? error.message : 'Failed to load dedications';
      this.errorMessage.set(message);
      this.items.set([]);
      this.filteredItems.set([]);
    } finally {
      this.loading.set(false);
    }
  }

  applyClientFilters(): void {
    const query = this.searchQuery.trim().toLowerCase();
    if (!query) {
      this.filteredItems.set(this.items());
      return;
    }
    this.filteredItems.set(
      this.items().filter(
        (item) =>
          item.displayName.toLowerCase().includes(query) ||
          item.slug.toLowerCase().includes(query),
      ),
    );
  }

  onSearchChange(): void {
    this.applyClientFilters();
  }

  yesNo(value: boolean): string {
    return value ? this.i18n.t('common_yes') : this.i18n.t('common_no');
  }
}
