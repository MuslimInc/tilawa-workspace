import { Component, Input, OnChanges } from '@angular/core';
import { CommonModule } from '@angular/common';

import {
  extractAvatarInitials,
  resolveAvatarColors,
  resolveAvatarSeed,
} from '../../utils/avatar.util';

export type TilawaAvatarSize = 'sm' | 'md' | 'lg';

@Component({
  selector: 'app-tilawa-avatar',
  standalone: true,
  imports: [CommonModule],
  template: `
    @if (showImage) {
      <img
        [src]="normalizedPhotoUrl!"
        [alt]="accessibleName"
        [attr.aria-label]="accessibleName"
        [class]="sizeClass"
        (error)="onImageError()"
      />
    } @else {
      <span
        role="img"
        [attr.aria-label]="accessibleName"
        [class]="sizeClass + ' tilawa-avatar-initials'"
        [style.background-color]="colors.bg"
        [style.color]="colors.fg"
      >
        @if (initials) {
          {{ initials }}
        } @else {
          <svg
            class="tilawa-avatar-icon"
            viewBox="0 0 24 24"
            fill="currentColor"
            aria-hidden="true"
          >
            <path
              d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"
            />
          </svg>
        }
      </span>
    }
  `,
  styles: `
    :host {
      display: inline-flex;
      flex-shrink: 0;
    }

    img,
    .tilawa-avatar-initials {
      border-radius: 9999px;
      object-fit: cover;
    }

    .tilawa-avatar-initials {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-weight: 700;
      line-height: 1;
      user-select: none;
    }

    .size-sm {
      width: 2rem;
      height: 2rem;
      font-size: 0.75rem;
    }

    .size-md {
      width: 2.5rem;
      height: 2.5rem;
      font-size: 0.875rem;
    }

    .size-lg {
      width: 6rem;
      height: 6rem;
      font-size: 1.5rem;
    }

    .tilawa-avatar-icon {
      width: 55%;
      height: 55%;
    }
  `,
})
export class TilawaAvatarComponent implements OnChanges {
  @Input() displayName = '';
  @Input() email: string | null = null;
  @Input() photoUrl: string | null = null;
  @Input() size: TilawaAvatarSize = 'md';

  imageError = false;
  normalizedPhotoUrl: string | null = null;

  ngOnChanges(): void {
    this.normalizedPhotoUrl = this.photoUrl?.trim() || null;
    this.imageError = false;
  }

  get showImage(): boolean {
    return !!this.normalizedPhotoUrl && !this.imageError;
  }

  get initials(): string {
    return extractAvatarInitials(this.displayName, this.email);
  }

  get colors() {
    return resolveAvatarColors(resolveAvatarSeed(this.displayName, this.email));
  }

  get accessibleName(): string {
    const name = this.displayName?.trim();
    if (name) {
      return name;
    }
    const mail = this.email?.trim();
    if (mail) {
      return mail;
    }
    return 'User avatar';
  }

  get sizeClass(): string {
    return `size-${this.size}`;
  }

  onImageError(): void {
    this.imageError = true;
  }
}
