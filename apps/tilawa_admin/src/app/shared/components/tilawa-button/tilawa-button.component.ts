import { Component, Input, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';

export type TilawaButtonVariant =
  | 'primary'
  | 'secondary'
  | 'danger'
  | 'success'
  | 'warning'
  | 'text';

@Component({
  selector: 'app-tilawa-button',
  standalone: true,
  imports: [CommonModule],
  host: {
    '[class.tilawa-btn-host-full]': 'fullWidth',
  },
  template: `
    <button
      [attr.type]="type"
      [disabled]="isDisabled"
      [class]="controlClass"
      [attr.aria-busy]="loading ? 'true' : null"
      (click)="onClick($event)"
    >
      @if (loading) {
        <span class="tilawa-btn-spinner" aria-hidden="true"></span>
      }
      @if (label) {
        {{ label }}
      } @else {
        <ng-content />
      }
    </button>
  `,
  styles: `
    :host {
      display: inline-flex;
    }

    :host(.tilawa-btn-host-full) {
      display: flex;
      width: 100%;
    }

    :host(.tilawa-btn-host-full) .tilawa-btn {
      width: 100%;
    }

    .tilawa-btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 0.5rem;
      min-height: var(--tilawa-min-touch);
      border-radius: var(--tilawa-radius-md);
      font-size: 0.875rem;
      font-weight: 600;
      line-height: 1.25rem;
      padding: 0.5rem 1rem;
      border: 1px solid transparent;
      cursor: pointer;
      text-decoration: none;
      transition:
        background-color var(--tilawa-duration-fast) ease,
        border-color var(--tilawa-duration-fast) ease,
        color var(--tilawa-duration-fast) ease,
        opacity var(--tilawa-duration-fast) ease;
    }

    .tilawa-btn:disabled {
      opacity: 0.5;
      cursor: not-allowed;
      pointer-events: none;
    }

    .tilawa-btn:focus-visible {
      outline: 2px solid var(--tilawa-primary);
      outline-offset: 2px;
    }

    .variant-primary {
      background-color: var(--tilawa-primary);
      color: var(--tilawa-on-primary);
    }

    .variant-primary:hover:not(:disabled) {
      background-color: var(--tilawa-primary-dark);
    }

    .variant-secondary {
      background-color: var(--tilawa-surface);
      color: var(--tilawa-on-surface);
      border-color: var(--tilawa-outline);
    }

    .variant-secondary:hover:not(:disabled) {
      background-color: var(--tilawa-surface-high);
    }

    @media (prefers-color-scheme: dark) {
      .variant-secondary {
        background-color: var(--tilawa-surface-highest);
        border-color: rgb(139 94 60 / 0.55);
        color: var(--tilawa-on-surface);
      }

      .variant-secondary:hover:not(:disabled) {
        background-color: rgb(139 94 60 / 0.18);
        border-color: var(--tilawa-primary);
      }
    }

    .variant-danger {
      background-color: var(--tilawa-error);
      color: #fff;
    }

    .variant-danger:hover:not(:disabled) {
      filter: brightness(0.92);
    }

    .variant-success {
      background-color: var(--tilawa-success);
      color: #fff;
    }

    .variant-success:hover:not(:disabled) {
      filter: brightness(0.92);
    }

    .variant-warning {
      background-color: var(--tilawa-warning);
      color: #fff;
    }

    .variant-warning:hover:not(:disabled) {
      filter: brightness(0.92);
    }

    .variant-text {
      background: transparent;
      color: var(--tilawa-primary);
      min-height: auto;
      padding: 0.25rem 0.5rem;
    }

    .variant-text:hover:not(:disabled) {
      background-color: rgb(139 94 60 / 0.08);
    }

    @media (prefers-color-scheme: dark) {
      .variant-text {
        color: #e8c9a8;
      }

      .variant-text:hover:not(:disabled) {
        background-color: rgb(139 94 60 / 0.2);
      }
    }

    .size-sm {
      min-height: 2.25rem;
      padding: 0.375rem 0.75rem;
      font-size: 0.8125rem;
    }

    .size-xs {
      min-height: 2rem;
      padding: 0.25rem 0.5rem;
      font-size: 0.75rem;
      line-height: 1.125rem;
    }

    .size-full {
      width: 100%;
    }

    .tilawa-btn-spinner {
      width: 1rem;
      height: 1rem;
      border: 2px solid currentColor;
      border-inline-end-color: transparent;
      border-radius: 50%;
      animation: spin 0.6s linear infinite;
    }

    @keyframes spin {
      to {
        transform: rotate(360deg);
      }
    }
  `,
})
export class TilawaButtonComponent {
  private readonly router = inject(Router);

  @Input() variant: TilawaButtonVariant = 'primary';
  @Input() type: 'button' | 'submit' | 'reset' = 'button';
  @Input() size: 'md' | 'sm' | 'xs' = 'md';
  @Input() fullWidth = false;
  @Input() disabled = false;
  @Input() loading = false;
  @Input() label = '';
  /** When set, navigates via Router on click (use with [label]). */
  @Input() link?: string | readonly unknown[];

  get isDisabled(): boolean {
    return this.disabled || this.loading;
  }

  get controlClass(): string {
    const classes = ['tilawa-btn', `variant-${this.variant}`];
    if (this.size === 'sm') {
      classes.push('size-sm');
    }
    if (this.size === 'xs') {
      classes.push('size-xs');
    }
    if (this.fullWidth) {
      classes.push('size-full');
    }
    return classes.join(' ');
  }

  onClick(event: MouseEvent): void {
    if (this.isDisabled) {
      event.preventDefault();
      event.stopPropagation();
      return;
    }

    if (this.link === undefined) {
      return;
    }

    const commands = Array.isArray(this.link) ? this.link : [this.link];
    void this.router.navigate(commands);
  }
}
