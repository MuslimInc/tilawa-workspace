import { APP_INITIALIZER, ApplicationConfig, provideZonelessChangeDetection } from '@angular/core';
import { provideHttpClient } from '@angular/common/http';
import { provideRouter } from '@angular/router';
import { I18nService } from './core/i18n/i18n.service';
import { initializeApp, provideFirebaseApp } from '@angular/fire/app';
import { getAuth, provideAuth } from '@angular/fire/auth';
import { browserLocalPersistence, setPersistence } from 'firebase/auth';
import { getFirestore, provideFirestore } from '@angular/fire/firestore';
import { getFunctions, provideFunctions } from '@angular/fire/functions';
import { environment } from '../environments/environment';

import { routes } from './app.routes';
import { NOTIFICATION_REPOSITORY } from './core/domain/repositories/notification.repository';
import { NotificationRepositoryImpl } from './core/data/repositories/notification.repository.impl';
import { TEACHER_APPLICATION_REPOSITORY } from './core/domain/repositories/teacher-application.repository';
import { FirebaseTeacherApplicationRepository } from './core/data/repositories/firebase-teacher-application.repository';
import { TEACHER_PROFILE_REPOSITORY } from './core/domain/repositories/teacher-profile.repository';
import { FirebaseTeacherProfileRepository } from './core/data/repositories/firebase-teacher-profile.repository';
import { QURAN_SESSIONS_USER_REPOSITORY } from './core/domain/repositories/quran-sessions-user.repository';
import { FirebaseQuranSessionsUserRepository } from './core/data/repositories/firebase-quran-sessions-user.repository';
import { AUTH_SESSION_REPOSITORY } from './core/domain/repositories/auth-session.repository';
import { FirebaseAuthSessionRepository } from './core/data/repositories/firebase-auth-session.repository';
import { MODERATION_GATEWAY } from './core/domain/repositories/moderation.gateway';
import { FirebaseModerationGateway } from './core/data/repositories/firebase-moderation.gateway';
import { USER_DELETION_GATEWAY } from './core/domain/repositories/user-deletion.gateway';
import { FirebaseUserDeletionGateway } from './core/data/repositories/firebase-user-deletion.gateway';
import { SESSION_READ_REPOSITORY } from './core/domain/repositories/session-read.repository';
import { FirebaseSessionReadRepository } from './core/data/repositories/firebase-session-read.repository';
import { SESSION_AUDIT_REPOSITORY } from './core/domain/repositories/session-audit.repository';
import { FirebaseSessionAuditRepository } from './core/data/repositories/firebase-session-audit.repository';
import { CALL_TRACKING_REPOSITORY } from './core/domain/repositories/call-tracking.repository';
import { FirebaseCallTrackingRepository } from './core/data/repositories/firebase-call-tracking.repository';
import { SESSION_MODERATION_GATEWAY } from './core/domain/repositories/session-moderation.gateway';
import { FirebaseSessionModerationGateway } from './core/data/repositories/firebase-session-moderation.gateway';
import { SESSION_REPORT_READ_REPOSITORY } from './core/domain/repositories/session-report-read.repository';
import { FirebaseSessionReportReadRepository } from './core/data/repositories/firebase-session-report-read.repository';
import { SESSION_DISPUTE_READ_REPOSITORY } from './core/domain/repositories/session-dispute-read.repository';
import { FirebaseSessionDisputeReadRepository } from './core/data/repositories/firebase-session-dispute-read.repository';
import { WALLET_READ_REPOSITORY } from './core/domain/repositories/wallet-read.repository';
import { FirebaseWalletReadRepository } from './core/data/repositories/firebase-wallet-read.repository';
import { TILAWA_USER_REPOSITORY } from './core/domain/repositories/tilawa-user.repository';
import { FirebaseTilawaUserRepository } from './core/data/repositories/firebase-tilawa-user.repository';
import { AUTH_ADMIN_GATEWAY } from './core/domain/repositories/auth-admin.gateway';
import { FirebaseAuthAdminGateway } from './core/data/repositories/firebase-auth-admin.gateway';

function initializeI18n(i18n: I18nService): () => Promise<void> {
  return () => i18n.initialize();
}

export const appConfig: ApplicationConfig = {
  providers: [
    provideZonelessChangeDetection(),
    provideHttpClient(),
    {
      provide: APP_INITIALIZER,
      useFactory: initializeI18n,
      deps: [I18nService],
      multi: true,
    },
    provideRouter(routes),
    provideFirebaseApp(() => initializeApp(environment.firebase)),
    provideAuth(() => {
      const auth = getAuth();
      void setPersistence(auth, browserLocalPersistence);
      return auth;
    }),
    provideFirestore(() => getFirestore()),
    provideFunctions(() => getFunctions()),
    { provide: NOTIFICATION_REPOSITORY, useClass: NotificationRepositoryImpl },
    {
      provide: TEACHER_APPLICATION_REPOSITORY,
      useClass: FirebaseTeacherApplicationRepository,
    },
    {
      provide: TEACHER_PROFILE_REPOSITORY,
      useClass: FirebaseTeacherProfileRepository,
    },
    {
      provide: QURAN_SESSIONS_USER_REPOSITORY,
      useClass: FirebaseQuranSessionsUserRepository,
    },
    { provide: AUTH_SESSION_REPOSITORY, useClass: FirebaseAuthSessionRepository },
    { provide: MODERATION_GATEWAY, useClass: FirebaseModerationGateway },
    { provide: USER_DELETION_GATEWAY, useClass: FirebaseUserDeletionGateway },
    {
      provide: SESSION_READ_REPOSITORY,
      useClass: FirebaseSessionReadRepository,
    },
    {
      provide: SESSION_AUDIT_REPOSITORY,
      useClass: FirebaseSessionAuditRepository,
    },
    {
      provide: CALL_TRACKING_REPOSITORY,
      useClass: FirebaseCallTrackingRepository,
    },
    {
      provide: SESSION_MODERATION_GATEWAY,
      useClass: FirebaseSessionModerationGateway,
    },
    {
      provide: SESSION_REPORT_READ_REPOSITORY,
      useClass: FirebaseSessionReportReadRepository,
    },
    {
      provide: SESSION_DISPUTE_READ_REPOSITORY,
      useClass: FirebaseSessionDisputeReadRepository,
    },
    {
      provide: WALLET_READ_REPOSITORY,
      useClass: FirebaseWalletReadRepository,
    },
    {
      provide: TILAWA_USER_REPOSITORY,
      useClass: FirebaseTilawaUserRepository,
    },
    { provide: AUTH_ADMIN_GATEWAY, useClass: FirebaseAuthAdminGateway },
  ],
};

