import { Component } from '@angular/core';
import { TranslatePipe } from '../../core/i18n/translate.pipe';
import { PageHeaderComponent } from '../../shared/components/page-header/page-header.component';
import { TilawaCardComponent } from '../../shared/components/tilawa-card/tilawa-card.component';
import { TilawaEmptyStateComponent } from '../../shared/components/tilawa-empty-state/tilawa-empty-state.component';

@Component({
  selector: 'app-surahs',
  imports: [
    TranslatePipe,
    PageHeaderComponent,
    TilawaCardComponent,
    TilawaEmptyStateComponent,
  ],
  templateUrl: './surahs.component.html',
})
export class SurahsComponent {}
