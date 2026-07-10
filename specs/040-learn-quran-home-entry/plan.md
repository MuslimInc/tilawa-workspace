# Implementation Plan: Learn Quran Home Entry Strategy (ADR-007)

**Feature Branch**: `040-learn-quran-home-entry`  
**Created**: 2026-07-10  
**Status**: Approved / Implemented  

---

## Proposed Changes

### Component 1: Domain / Data Layer (Quran Sessions & Preferences)

We use the existing package-level domain entities and classifiers from the `quran_sessions` package:
- `GetStudentSessionsUseCase`
- `GetSessionAggregateUseCase`
- `SessionListClassifier.isStudentPending`
- `SessionListClassifier.isOngoing`
- `SessionListClassifier.isImminent`

To track interest state and practice history without accessing `SharedPreferences` directly from the Cubit, we introduce a new abstraction:
- [HomeLearningPreferenceStore](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/features/home/presentation/services/home_learning_preference_store.dart)

### Component 2: Presentation Layer (Cubit / State)

We implement `HomeLearningCubit` and `HomeLearningState` to resolve the priority state.
- [HomeLearningCubit](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/features/home/presentation/cubit/home_learning_cubit.dart)
- [HomeLearningState](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/features/home/presentation/cubit/home_learning_state.dart)

### Component 3: Presentation Layer (UI Cards)

We create specialized custom card widgets styled with the Tilawa design tokens:
- `HomeLearningInterestCard`
- `HomeLearningNextSessionCard`
- `HomeLearningPendingBookingCard`
- `HomeLearningRevisionCard`

All are defined in:
- [home_learning_cards.dart](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/features/home/presentation/widgets/home_learning_cards.dart)

---

## Verification Plan

### Automated Tests
- Unit tests: [home_learning_cubit_test.dart](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/test/features/home/presentation/cubit/home_learning_cubit_test.dart)
- Widget tests: [home_learning_cards_test.dart](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/test/features/home/presentation/widgets/home_learning_cards_test.dart)

Commands to run:
```bash
flutter test test/features/home/presentation/cubit/home_learning_cubit_test.dart
flutter test test/features/home/presentation/widgets/home_learning_cards_test.dart
```

### Manual Verification
- Verify layout behaves responsively under various display scales.
- Verify fallback behavior when APIs throw errors.
