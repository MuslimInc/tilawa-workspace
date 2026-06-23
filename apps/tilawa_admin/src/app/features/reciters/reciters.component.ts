import { Component } from '@angular/core';
import { TranslatePipe } from '../../core/i18n/translate.pipe';

@Component({
  selector: 'app-reciters',
  imports: [TranslatePipe],
  templateUrl: './reciters.component.html',
  styleUrl: './reciters.css',
})
export class RecitersComponent {}
