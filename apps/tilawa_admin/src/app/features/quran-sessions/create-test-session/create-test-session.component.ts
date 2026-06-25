import { Component, OnDestroy, OnInit, inject } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { CreateTestSessionFacade } from './create-test-session.facade';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { Subject, Subscription } from 'rxjs';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-create-test-session',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule],
  templateUrl: './create-test-session.component.html',
  styleUrl: './create-test-session.component.css'
})
export class CreateTestSessionComponent implements OnInit, OnDestroy {
  private readonly fb = inject(FormBuilder);
  readonly facade = inject(CreateTestSessionFacade);

  form: FormGroup;

  private readonly studentSearch$ = new Subject<string>();
  private readonly teacherSearch$ = new Subject<string>();
  private readonly subs = new Subscription();

  constructor() {
    this.form = this.fb.group({
      studentId: ['', Validators.required],
      teacherId: ['', Validators.required],
      date: ['', Validators.required],
      startTime: ['', Validators.required],
      endTime: ['', Validators.required],
      callType: ['externalMeeting', Validators.required]
    });
  }

  ngOnInit(): void {
    // Debounce prefix searches so we don't fire Firestore queries per keystroke.
    this.subs.add(
      this.studentSearch$
        .pipe(debounceTime(250), distinctUntilChanged())
        .subscribe((query) => {
          if (query.length >= 3) this.facade.searchStudents(query);
        }),
    );
    this.subs.add(
      this.teacherSearch$
        .pipe(debounceTime(250), distinctUntilChanged())
        .subscribe((query) => {
          if (query.length >= 3) this.facade.searchTeachers(query);
        }),
    );
  }

  ngOnDestroy(): void {
    this.subs.unsubscribe();
  }

  onStudentSearch(event: Event): void {
    const query = (event.target as HTMLInputElement).value;
    this.studentSearch$.next(query);
  }

  onTeacherSearch(event: Event): void {
    const query = (event.target as HTMLInputElement).value;
    this.teacherSearch$.next(query);
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
