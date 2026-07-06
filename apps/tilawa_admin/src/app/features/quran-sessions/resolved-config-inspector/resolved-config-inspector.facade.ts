import { Injectable, inject } from '@angular/core';
import { Functions, httpsCallable } from '@angular/fire/functions';
import { BehaviorSubject } from 'rxjs';

export interface InspectorState {
  loading: boolean;
  error: string | null;
  result: any | null;
}

@Injectable({
  providedIn: 'root'
})
export class ResolvedConfigInspectorFacade {
  private readonly functions = inject(Functions);
  
  readonly loading$ = new BehaviorSubject<boolean>(false);
  readonly error$ = new BehaviorSubject<string | null>(null);
  readonly result$ = new BehaviorSubject<any | null>(null);

  async inspect(studentId: string, teacherId: string) {
    this.loading$.next(true);
    this.error$.next(null);
    this.result$.next(null);
    
    try {
      const getResolvedSessionConfig = httpsCallable(this.functions, 'getResolvedSessionConfig');
      const res = await getResolvedSessionConfig({ studentId, teacherId });
      this.result$.next(res.data);
    } catch (e: any) {
      console.error('Inspector error:', e);
      this.error$.next(e.message || 'An error occurred during inspection');
    } finally {
      this.loading$.next(false);
    }
  }
}
