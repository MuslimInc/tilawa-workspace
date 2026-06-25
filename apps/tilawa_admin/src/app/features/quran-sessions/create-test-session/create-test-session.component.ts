import { Component, inject } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { CreateTestSessionFacade } from './create-test-session.facade';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-create-test-session',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule],
  templateUrl: './create-test-session.component.html',
  styleUrl: './create-test-session.component.css'
})
export class CreateTestSessionComponent {
  private readonly fb = inject(FormBuilder);
  readonly facade = inject(CreateTestSessionFacade);

  form: FormGroup;

  constructor() {
    this.form = this.fb.group({
      studentId: ['', Validators.required],
      teacherId: ['', Validators.required],
      date: ['', Validators.required],
      startTime: ['', Validators.required],
      endTime: ['', Validators.required],
      callType: ['externalMeeting', Validators.required]
    });

    this.setupSearch();
  }

  private setupSearch(): void {
    // We could use form controls for search inputs or just generic inputs.
    // For simplicity, let's just trigger facade search from the view via keyup events
    // and store the selected ids in the form.
  }

  onStudentSearch(event: Event): void {
    const query = (event.target as HTMLInputElement).value;
    if (query.length >= 3) {
      this.facade.searchStudents(query);
    }
  }

  onTeacherSearch(event: Event): void {
    const query = (event.target as HTMLInputElement).value;
    if (query.length >= 3) {
      this.facade.searchTeachers(query);
    }
  }

  selectStudent(id: string): void {
    this.form.patchValue({ studentId: id });
    // clear results to hide dropdown
    this.facade.studentResults.set([]);
  }

  selectTeacher(id: string): void {
    this.form.patchValue({ teacherId: id });
    // clear results to hide dropdown
    this.facade.teacherResults.set([]);
  }

  onSubmit(): void {
    if (this.form.invalid) return;
    this.facade.createSession(this.form.value);
  }
}
