import {
  ChangeDetectionStrategy,
  Component,
  EventEmitter,
  Input,
  OnInit,
  Output,
  inject,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

import { TeacherListItemVm } from '../../../core/data/view-models/quran-sessions.view-model';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { TilawaButtonComponent } from '../../../shared/components/tilawa-button/tilawa-button.component';
import { TeacherPricingFacade, TeacherPricingMode } from './teacher-pricing.facade';

/**
 * Admin panel to set a teacher's session price override (Free / Fixed) or
 * clear it back to the market price. Writes go through
 * `setTeacherSessionPricing`; the server is authoritative.
 */
@Component({
  selector: 'app-teacher-pricing-panel',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, FormsModule, TranslatePipe, TilawaButtonComponent],
  templateUrl: './teacher-pricing-panel.component.html',
  styleUrl: './teacher-pricing-panel.component.css',
})
export class TeacherPricingPanelComponent implements OnInit {
  private readonly facade = inject(TeacherPricingFacade);

  @Input({ required: true }) teacher!: TeacherListItemVm;
  @Output() readonly saved = new EventEmitter<void>();
  @Output() readonly closed = new EventEmitter<void>();

  readonly isSubmitting = this.facade.isSubmitting;
  readonly error = this.facade.error;
  readonly savedState = this.facade.saved;

  mode: TeacherPricingMode = 'inherit';
  amount: number | null = null;
  currencyCode = '';

  ngOnInit(): void {
    this.facade.reset();
    const override = this.teacher.sessionPriceOverride;
    if (override?.enabled) {
      this.mode = override.amount && override.amount > 0 ? 'fixed' : 'free';
      this.amount = override.amount ?? null;
      this.currencyCode = override.currencyCode ?? '';
    }
  }

  /** Human summary of the teacher's current pricing for the panel header. */
  currentSummaryKey(): string {
    const override = this.teacher.sessionPriceOverride;
    if (!override?.enabled) return 'teacherPricing_currentInherit';
    if (!override.amount || override.amount <= 0) return 'teacherPricing_currentFree';
    return 'teacherPricing_current';
  }

  currentSummaryValue(): string {
    const override = this.teacher.sessionPriceOverride;
    if (!override?.enabled || !override.amount || override.amount <= 0) return '';
    return `${override.amount} ${override.currencyCode ?? ''}`.trim();
  }

  /**
   * i18n key for the pricing-source row. Authoritative for *this* teacher's
   * override (the value the admin is editing); mirrors the server's
   * `effectivePricingSource` for the override-vs-market distinction.
   */
  effectivePricingSourceKey(): string {
    return this.teacher.sessionPriceOverride?.enabled
      ? 'teacherPricing_sourceOverride'
      : 'teacherPricing_sourceMarket';
  }

  /**
   * i18n key for the effective-price row, or '' when a raw amount is shown
   * (see [effectivePriceValue]).
   */
  effectivePriceKey(): string {
    const override = this.teacher.sessionPriceOverride;
    if (!override?.enabled) return 'teacherPricing_effectiveInherit';
    if (!override.amount || override.amount <= 0) {
      return 'teacherPricing_effectiveFree';
    }
    return '';
  }

  /** Raw effective price when a fixed override is set; '' otherwise. */
  effectivePriceValue(): string {
    const override = this.teacher.sessionPriceOverride;
    if (!override?.enabled || !override.amount || override.amount <= 0) {
      return '';
    }
    return `${override.amount} ${override.currencyCode ?? ''}`.trim();
  }

  async onSubmit(): Promise<void> {
    const ok = await this.facade.submit({
      teacherId: this.teacher.id,
      mode: this.mode,
      amount: this.amount,
      currencyCode: this.currencyCode,
    });
    if (ok) {
      this.saved.emit();
    }
  }
}
