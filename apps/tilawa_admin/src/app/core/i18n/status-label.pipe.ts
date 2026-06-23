import { Pipe, PipeTransform, inject } from '@angular/core';

import { I18nService } from './i18n.service';

@Pipe({
  name: 'statusLabel',
  standalone: true,
  pure: false,
})
export class StatusLabelPipe implements PipeTransform {
  private readonly i18n = inject(I18nService);

  transform(status: string): string {
    this.i18n.language();
    this.i18n.ready();
    return this.i18n.t(`status_${status}`);
  }
}
