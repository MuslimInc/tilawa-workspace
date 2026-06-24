import { Component } from '@angular/core';
import { TranslatePipe } from '../../core/i18n/translate.pipe';
import { PageHeaderComponent } from '../../shared/components/page-header/page-header.component';
import { TilawaButtonComponent } from '../../shared/components/tilawa-button/tilawa-button.component';
import { TilawaCardComponent } from '../../shared/components/tilawa-card/tilawa-card.component';
import { TilawaEmptyStateComponent } from '../../shared/components/tilawa-empty-state/tilawa-empty-state.component';

@Component({
  selector: 'app-reciters',
  imports: [
    TranslatePipe,
    PageHeaderComponent,
    TilawaButtonComponent,
    TilawaCardComponent,
    TilawaEmptyStateComponent,
  ],
  templateUrl: './reciters.component.html',
})
export class RecitersComponent {}
