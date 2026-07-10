import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ResolvedConfigInspectorFacade } from './resolved-config-inspector.facade';
import { PageHeaderComponent } from '../../../shared/components/page-header/page-header.component';
import { TilawaCardComponent } from '../../../shared/components/tilawa-card/tilawa-card.component';
import { TilawaLoadingStateComponent } from '../../../shared/components/tilawa-loading-state/tilawa-loading-state.component';
import { TilawaErrorStateComponent } from '../../../shared/components/tilawa-error-state/tilawa-error-state.component';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';

@Component({
  selector: 'app-resolved-config-inspector',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    PageHeaderComponent,
    TilawaCardComponent,
    TilawaLoadingStateComponent,
    TilawaErrorStateComponent,
    TranslatePipe
  ],
  templateUrl: './resolved-config-inspector.component.html'
})
export class ResolvedConfigInspectorComponent {
  private readonly facade = inject(ResolvedConfigInspectorFacade);
  private readonly fb = inject(FormBuilder);

  loading$ = this.facade.loading$;
  error$ = this.facade.error$;
  result$ = this.facade.result$;

  inspectorForm: FormGroup = this.fb.group({
    studentId: ['', Validators.required],
    teacherId: ['', Validators.required]
  });

  inspect() {
    if (this.inspectorForm.invalid) return;
    
    const { studentId, teacherId } = this.inspectorForm.value;
    this.facade.inspect(studentId, teacherId);
  }
}
