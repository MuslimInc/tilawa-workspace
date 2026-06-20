# quran_sessions

A fully isolated Flutter package that powers the **Quran Tutoring Sessions** feature — teacher discovery, slot booking, session management, and in-app calling — for the Tilawa / Me Muslim app.

---

## Purpose

Enable users to book scheduled 1-on-1 Quran learning, memorization, revision, and recitation sessions with verified Quran teachers. The package handles the entire lifecycle: browse teachers → pick a slot → pay → join the session → leave a review.

---

## Package boundaries

### What belongs here

| Layer | Contents |
|---|---|
| **Domain** | Entities, repository interfaces, use cases, `QuranSessionsFailure` sealed types |
| **Data** | DTOs, mappers, datasource interfaces, repository implementations |
| **Presentation** | BLoC triads (event/state/bloc), screens, widgets, route constants, `QuranSessionsFailureUi` extension |
| **Boundaries** | Scheduling policies, payment interfaces, call provider interfaces + placeholder implementations |

### What must NOT be added here

- Direct Firebase imports (`cloud_firestore`, `firebase_auth`, etc.)
- Agora SDK (`agora_rtc_engine`) — inject via `AgoraCallProvider` when V2 is scoped
- WebRTC SDK (`flutter_webrtc`) — inject via `WebRtcCallProvider` when V4 is scoped
- Payment SDK (Stripe, PayPal, etc.) — inject via `PaymentProvider`
- App-specific routing logic — the host app wires `QuranSessionsRoutes` into its GoRouter
- Hard-coded colors, text styles, or spacing — consume the host app's design system via constructor injection or `Theme.of(context)`
- `BuildContext` below the presentation layer

---

## Architecture

```
packages/quran_sessions/
├── lib/
│   ├── quran_sessions.dart          ← PUBLIC API — only file the host app imports
│   └── src/
│       ├── domain/
│       │   ├── entities/            ← Pure Dart, no Flutter
│       │   ├── failures/            ← QuranSessionsFailure sealed class + all subtypes
│       │   ├── repositories/        ← Abstract interfaces (return Either<QuranSessionsFailure, T>)
│       │   └── usecases/            ← Thin orchestrators; one public call() method each
│       ├── data/
│       │   ├── dtos/                ← Raw JSON shapes
│       │   ├── mappers/             ← DTO → domain extension methods
│       │   ├── datasources/         ← Remote datasource abstract interfaces
│       │   └── repositories/        ← Concrete implementations of domain interfaces
│       ├── presentation/
│       │   ├── blocs/               ← One BLoC triad (event/state/bloc) per feature screen
│       │   │   ├── teacher_list/
│       │   │   ├── teacher_profile/
│       │   │   ├── booking/
│       │   │   ├── my_sessions/
│       │   │   └── teacher_dashboard/
│       │   ├── failure_ui/          ← QuranSessionsFailureUi extension (override in host app)
│       │   ├── screens/             ← Passive BlocBuilder / BlocConsumer screens
│       │   ├── widgets/             ← Reusable UI components
│       │   └── router/              ← Route path constants + screen builder helpers
│       └── boundaries/
│           ├── scheduling/          ← AvailabilityProvider, BookingPolicy, CancellationPolicy, ReschedulePolicy
│           ├── payment/             ← PaymentProvider, TeacherPayoutProvider
│           └── call/                ← CallProvider, CallRoom, CallTokenProvider + placeholder impls
└── test/
    ├── domain/                      ← Use case unit tests
    ├── data/                        ← Mapper unit tests
    ├── boundaries/                  ← Policy and provider contract tests
    ├── presentation/blocs/          ← bloc_test tests for all 5 BLoC triads
    └── helpers/
        ├── fixtures.dart            ← Entity builder helpers
        └── fakes/                   ← In-memory fakes for all repository/provider interfaces
```

---

## How the host app integrates this package

### 1. Add to workspace pubspec.yaml

```yaml
workspace:
  - packages/quran_sessions   # already added
```

### 2. Add as a dependency in apps/tilawa/pubspec.yaml

```yaml
dependencies:
  quran_sessions:
    path: ../../packages/quran_sessions
```

### 3. Register DI bindings (get_it / injectable)

```dart
// In your DI module:
getIt.registerFactory<TeacherRemoteDataSource>(() => MyApiTeacherDataSource(dio));
getIt.registerFactory<TeacherRepository>(() => TeacherRepositoryImpl(getIt()));
getIt.registerFactory<GetTeachersUseCase>(() => GetTeachersUseCase(getIt()));

// Call boundary (MVP — external meetings):
getIt.registerFactory<CallProvider>(() => ExternalMeetingCallProvider(
  getMeetingUrl: (id) => getIt<SessionRepository>().getSessionById(id)
      .then((r) => r.fold((_) => '', (s) => s.meetingLink ?? '')),
  urlLauncher: (url) => launchUrl(Uri.parse(url)),
));

// Payment boundary (inject your chosen SDK implementation):
getIt.registerFactory<PaymentProvider>(() => StripePaymentProvider(...));
```

### 4. Wire routes into GoRouter

```dart
// In app_router_config.dart, add inside your ShellRoute children:
GoRoute(
  path: QuranSessionsRoutes.home,
  builder: (_, __) => const QuranSessionsHomeScreen(),
  routes: [
    GoRoute(
      path: 'teachers',
      builder: (_, __) => const TeacherListScreen(),
      routes: [
        GoRoute(
          path: ':teacherId',
          builder: (ctx, state) => TeacherProfileScreen(
            teacherId: state.pathParameters['teacherId']!,
          ),
          routes: [
            GoRoute(
              path: 'book',
              builder: (ctx, state) => BookingScreen(
                teacherId: state.pathParameters['teacherId']!,
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: 'my',
      builder: (_, __) => MySessionsScreen(studentId: currentUserId),
    ),
    GoRoute(
      path: 'dashboard',
      builder: (_, __) => TeacherDashboardScreen(teacherId: currentUserId),
    ),
  ],
),
```

### 5. Register BLoCs in get_it

Each BLoC requires its use cases; use `registerFactory` so a new instance is created per screen:

```dart
// Teacher list
getIt.registerFactory(() => TeacherListBloc(getIt<GetTeachersUseCase>()));

// Teacher profile
getIt.registerFactory(() => TeacherProfileBloc(
  getTeacherProfile: getIt(),
  getTeacherAvailability: getIt(),
));

// Booking
getIt.registerFactory(() => BookingBloc(
  getTeacherAvailability: getIt(),
  createBooking: getIt(),
));

// My sessions
getIt.registerFactory(() => MySessionsBloc(
  getStudentSessions: getIt(),
  cancelBooking: getIt(),
  submitReview: getIt(),
));

// Teacher dashboard
getIt.registerFactory(() => TeacherDashboardBloc(
  getTeacherSessions: getIt(),
  getTeacherAvailability: getIt(),
  availabilityProvider: getIt(),
));
```

Provide each BLoC to its screen using `BlocProvider`:

```dart
BlocProvider(
  create: (_) => getIt<TeacherListBloc>()
    ..add(const LoadTeachersRequested()),
  child: const TeacherListScreen(studentId: userId),
)
```

### 6. Override the failure UI extension (optional)

The package ships with English developer-facing messages. For production l10n, define your own extension in the host app:

```dart
// apps/tilawa/lib/core/extensions/failure_l10n.dart
extension TilawaFailureL10n on QuranSessionsFailure {
  @override
  String toLocalizedMessage(BuildContext context) => switch (this) {
    NetworkFailure()         => context.l10n.errorNetwork,
    TimeoutFailure()         => context.l10n.errorTimeout,
    UnauthorizedFailure() ||
    ServerFailure(statusCode: 401) => context.l10n.errorUnauthorized,
    ServerFailure()          => context.l10n.errorServer,
    SlotUnavailableFailure() => context.l10n.errorSlotUnavailable,
    BookingConflictFailure() => context.l10n.errorBookingConflict,
    NotFoundFailure()        => context.l10n.errorNotFound,
    ValidationFailure(:final field) => context.l10n.errorValidation(field),
    CacheFailure()           => context.l10n.errorCache,
    UnknownFailure()         => context.l10n.errorUnknown,
  };
}
```

Screens call `state.failure.toLocalizedMessage(context)` — BLoCs and states never produce Strings.

---

## Future phases

### MVP — External meeting links
- `SessionCallType.externalMeeting`
- `ExternalMeetingCallProvider` opens Zoom/Meet URL via `url_launcher`
- No SDK dependency; ships immediately

### V2 — Agora voice
- Inject `AgoraCallProvider` (currently throws `UnimplementedError`)
- Add `agora_rtc_engine` to pubspec
- Use `CallTokenProvider` to fetch RTC tokens from backend
- Replace `UnimplementedError` bodies in `AgoraCallProvider`

### V3 — Agora video
- Extend `AgoraCallProvider` with video channel support
- Add teacher/student camera toggle state
- Add `SessionCallType.videoCall` flow in `BookingScreen`

### V4 — Custom WebRTC (only if justified)
- Inject `WebRtcCallProvider` (currently throws `UnimplementedError`)
- Add `flutter_webrtc` + signalling server integration
- Only pursue this if Agora pricing or vendor lock-in becomes a blocker

---

## Running tests

```sh
# From packages/quran_sessions/
flutter test

# From workspace root via melos
melos run test
```

## Known risks and coupling points

| Risk | Mitigation |
|---|---|
| BLoC event handlers use `restartable()`/`droppable()` from `bloc_concurrency` — misuse causes dropped events | Read each BLoC's transformer choice before adding new event handlers |
| `toLocalizedMessage` default returns English strings — not production-ready | Host app must override with its own `extension ... on QuranSessionsFailure` in the l10n layer |
| DTOs have hand-written `fromJson` — no codegen | Add `json_serializable` + `freezed` once the API contract is finalised |
| `ExternalMeetingCallProvider` depends on `url_launcher` being injected | The package avoids a hard dep; the host app supplies the launcher callback |
