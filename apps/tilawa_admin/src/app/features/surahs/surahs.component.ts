import { Component } from '@angular/core';
import { TranslatePipe } from '../../core/i18n/translate.pipe';

@Component({
  selector: 'app-surahs',
  imports: [TranslatePipe],
  templateUrl: './surahs.component.html',
  styleUrl: './surahs.css',
})
export class SurahsComponent {}
