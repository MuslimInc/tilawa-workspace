import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

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
  template: `
    <button
      [attr.type]="type"
      [disabled]="disabled || loading"
      [class]="buttonClass"
      [attr.aria-busy]="loading ? 'true' : null"
    >
      @if (loading) {
        <span class="tilawa-btn-spinner" aria-hidden="true"></span>
      }
      <ng-content />
    </button>
  `,
  styles: `
    :host {
      display: inline-flex;
    }

    button {
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
      transition:
        background-color var(--tilawa-duration-fast) ease,
        border-color var(--tilawa-duration-fast) ease,
        color var(--tilawa-duration-fast) ease,
        opacity var(--tilawa-duration-fast) ease;
    }

    button:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }

    button:focus-visible {
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

    .size-sm {
      min-height: 2.25rem;
      padding: 0.375rem 0.75rem;
      font-size: 0.8125rem;
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
  @Input() variant: TilawaButtonVariant = 'primary';
  @Input() type: 'button' | 'submit' | 'reset' = 'button';
  @Input() size: 'md' | 'sm' = 'md';
  @Input() fullWidth = false;
  @Input() disabled = false;
  @Input() loading = false;

  get buttonClass(): string {
    const classes = [`variant-${this.variant}`];
    if (this.size === 'sm') {
      classes.push('size-sm');
    }
    if (this.fullWidth) {
      classes.push('size-full');
    }
    return classes.join(' ');
  }
}
