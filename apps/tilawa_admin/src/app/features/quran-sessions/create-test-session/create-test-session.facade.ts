import { Injectable, inject, signal } from '@angular/core';
import { Functions, httpsCallable } from '@angular/fire/functions';
import { Router } from '@angular/router';
import { TILAWA_USER_REPOSITORY } from '../../../core/domain/repositories/tilawa-user.repository';
import { TilawaUser } from '../../../core/domain/entities/tilawa-user.entity';
import { TEACHER_PROFILE_REPOSITORY } from '../../../core/domain/repositories/teacher-profile.repository';
import { TeacherProfile } from '../../../core/domain/entities/teacher-profile.entity';

export interface CreateAdminTestSessionRequest {
  studentId: string;
  teacherId: string;
  slotId: string;
  startsAt: string;
  endsAt: string;
  callType: 'externalMeeting' | 'voiceCall' | 'videoCall';
  callProvider?: string;
  idempotencyKey?: string;
}

export interface CreateBookingResult {
  bookingId: string;
  sessionId: string;
  lifecycleStatus: string;
  status: string;
}

@Injectable({ providedIn: 'root' })
export class CreateTestSessionFacade {
  private readonly functions = inject(Functions);
  private readonly router = inject(Router);
  private readonly userRepository = inject(TILAWA_USER_REPOSITORY);
  private readonly teacherRepository = inject(TEACHER_PROFILE_REPOSITORY);

  readonly studentResults = signal<TilawaUser[]>([]);
  readonly teacherResults = signal<TeacherProfile[]>([]);
  
  readonly isSearchingStudents = signal(false);
  readonly isSearchingTeachers = signal(false);
  readonly isSubmitting = signal(false);
  readonly error = signal<string | null>(null);

  async searchStudents(query: string): Promise<void> {
    if (!query || query.length < 3) {
      this.studentResults.set([]);
      return;
    }
    this.isSearchingStudents.set(true);
    try {
      const results = await this.userRepository.searchByPrefix?.(query);
      this.studentResults.set(results || []);
    } catch (e) {
      console.error('Failed to search students', e);
      this.studentResults.set([]);
    } finally {
      this.isSearchingStudents.set(false);
    }
  }

  async searchTeachers(query: string): Promise<void> {
    if (!query || query.length < 3) {
      this.teacherResults.set([]);
      return;
    }
    this.isSearchingTeachers.set(true);
    try {
      const results = await this.teacherRepository.searchActiveTeachers?.(query);
      this.teacherResults.set(results || []);
    } catch (e) {
      console.error('Failed to search teachers', e);
      this.teacherResults.set([]);
    } finally {
      this.isSearchingTeachers.set(false);
    }
  }

  async createSession(data: {
    studentId: string;
    teacherId: string;
    date: string;
    startTime: string;
    endTime: string;
    callType: 'externalMeeting' | 'voiceCall' | 'videoCall';
  }): Promise<void> {
    this.isSubmitting.set(true);
    this.error.set(null);

    try {
      const startDateTime = new Date(`${data.date}T${data.startTime}:00`);
      if (isNaN(startDateTime.getTime())) {
        throw new Error('Invalid start date/time selected');
      }
      const startsAt = startDateTime.toISOString();
      
      const endDateTime = new Date(`${data.date}T${data.endTime}:00`);
      if (isNaN(endDateTime.getTime())) {
        throw new Error('Invalid end date/time selected');
      }
      const endsAt = endDateTime.toISOString();

      if (endDateTime <= startDateTime) {
        throw new Error('End time must be after start time');
      }

      const slotId = this.generateSlotId(startDateTime);

      const callable = httpsCallable<CreateAdminTestSessionRequest, CreateBookingResult>(
        this.functions,
        'createAdminTestQuranSession'
      );

      const result = await callable({
        studentId: data.studentId,
        teacherId: data.teacherId,
        slotId,
        startsAt,
        endsAt,
        callType: data.callType,
      });

      const sessionId = result.data.sessionId;
      await this.router.navigate(['/quran-sessions', 'sessions', sessionId]);
    } catch (e: any) {
      console.error('Failed to create test session:', e);
      this.error.set(e.message || 'An unknown error occurred');
    } finally {
      this.isSubmitting.set(false);
    }
  }

  private generateSlotId(date: Date): string {
    const yyyy = date.getUTCFullYear();
    const mm = String(date.getUTCMonth() + 1).padStart(2, '0');
    const dd = String(date.getUTCDate()).padStart(2, '0');
    const hh = String(date.getUTCHours()).padStart(2, '0');
    const min = String(date.getUTCMinutes()).padStart(2, '0');
    return `${yyyy}${mm}${dd}-${hh}${min}`;
  }
}
