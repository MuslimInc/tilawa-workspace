# [FEATURE NAME] - Tilawa Feature Checklist

**Purpose**: Verify feature meets Tilawa Workspace Constitution and quality standards  
**Created**: [DATE]  
**Feature**: [Link to spec.md]  
**Plan**: [Link to plan.md]  

---

## ✅ Architecture Verification

**Reference**: `.specify/memory/constitution.md` - Section I: Clean Architecture Boundaries

- [ ] CHK001 **Domain Layer**: No Flutter imports, no routing, no persistence code
- [ ] CHK002 **Domain Entities**: Immutable, pure Dart (no BLoC, no Platform-specific)
- [ ] CHK003 **Domain Repository Contracts**: Pure Dart interfaces, used by use cases
- [ ] CHK004 **Domain Use Cases**: Apply business rules, depend only on repository contracts
- [ ] CHK005 **Data Layer**: Implements domain repository contracts
- [ ] CHK006 **Data Models/Mappers**: Translate external formats → domain entities at layer boundary
- [ ] CHK007 **Data Sources**: Local (SharedPreferences/Hive) and remote (HTTP) implementations
- [ ] CHK008 **Presentation Layer**: Depends on domain abstractions, NOT data implementations directly
- [ ] CHK009 **Cross-Feature Dependencies**: Go through public APIs or shared packages (packages/core, packages/ui_kit)
- [ ] CHK010 **Dependency Direction**: All arrows point toward domain contracts

---

## ✅ State Management & Routing

**Reference**: `.specify/memory/constitution.md` - Section II: Reactive State Management & Routing

- [ ] CHK011 **BLoC/Cubit**: Feature state driven by BLoC, not scattered in widgets
- [ ] CHK012 **BLoC Events**: All user actions trigger events, not direct state mutations
- [ ] CHK013 **BLoC States**: Immutable, sealed/union recommended, represent all possible UI states
- [ ] CHK014 **Widget State**: Only ephemeral state (scroll, focus, animation) kept in widgets
- [ ] CHK015 **BlocBuilder/BlocListener**: Used for UI state rendering and side effects
- [ ] CHK016 **GoRouter Configuration**: All routes declared, builders are widget functions
- [ ] CHK017 **Deep Linking**: Supported if feature is entry point or reachable from deep link
- [ ] CHK018 **Route Guards**: Redirects implemented if feature requires authentication/permissions

---

## ✅ UI Kit & Design System

**Reference**: `.specify/memory/constitution.md` - Section III: Atomic Design & Tilawa UI Kit

- [ ] CHK019 **UI Kit Components**: Shared UI from `packages/ui_kit`, not custom reimplemented
- [ ] CHK020 **Component Classification**: Used components classified (foundation/atoms/molecules/organisms)
- [ ] CHK021 **Design Tokens**: Colors, typography, spacing from design tokens (not hardcoded)
- [ ] CHK022 **Localization**: i18n support via l10n.yaml, not English-only strings
- [ ] CHK023 **Theme Support**: Dark mode tested and working (if app supports dark theme)
- [ ] CHK024 **Responsive Behavior**: Compact (phone), medium (tablet), expanded layouts designed
- [ ] CHK025 **RTL Support**: Arabic/RTL text and icons properly mirrored, tested

---

## ✅ Testing & Coverage

**Reference**: `.specify/memory/constitution.md` - Section VI: Safe Refactoring & Delivery

- [ ] CHK026 **Domain Tests**: Entity, repository mock, use case tests written first (TDD)
- [ ] CHK027 **Data Tests**: Mapper, data source, repository impl tests with mocked external data
- [ ] CHK028 **BLoC Tests**: Event→state mappings tested, success/failure scenarios covered
- [ ] CHK029 **Widget Tests**: Page/component rendering with BLoC state changes
- [ ] CHK030 **Responsive Tests**: Compact/medium/expanded layouts rendering correctly
- [ ] CHK031 **RTL Tests**: Arabic text and icon mirroring behavior verified
- [ ] CHK032 **Accessibility Tests**: Touch targets ≥48dp, semantic labels, screen reader compatible
- [ ] CHK033 **Performance Tests**: Critical path measured (startup, scroll, user interactions)
- [ ] CHK034 **Test Coverage**: Critical paths ≥80%, no untested error handling

---

## ✅ Performance & Low Jank

**Reference**: `.specify/memory/constitution.md` - Section IV: Performance-First Flutter Delivery

- [ ] CHK035 **Build Optimization**: Hot paths avoid expensive work in `build()`
- [ ] CHK036 **Lazy Loading**: Lists, grids use ListView.builder/GridView.builder with visible item count
- [ ] CHK037 **Caching**: Images, data cached appropriately (memory/disk/network layer)
- [ ] CHK038 **Frame Budget**: Feature target 60 fps, raster time <16.7ms
- [ ] CHK039 **Startup Time**: Cold launch <500ms from app root to first feature frame
- [ ] CHK040 **Smooth Scrolling**: No jank when scrolling through content (if scrollable)
- [ ] CHK041 **Quran Text Rendering**: If rendering Quranic text, uses QCF fonts, pre-warmed
- [ ] CHK042 **Memory**: No memory leaks detected, disposal patterns used (StreamSubscription, AnimationController, etc.)

---

## ✅ Observability & Diagnostics

**Reference**: `.specify/memory/constitution.md` - Section V: Structured Observability & Diagnostics

- [ ] CHK043 **Structured Logging**: BLoC state transitions logged with context
- [ ] CHK044 **Error Logging**: Failures logged with stack trace and error type
- [ ] CHK045 **Route Logging**: Route changes logged (user navigation flow)
- [ ] CHK046 **Async Duration Logging**: Long operations (API calls, file I/O) timed and logged
- [ ] CHK047 **User Action Logging**: Analytics events for critical user flows
- [ ] CHK048 **Retry Logic**: Recoverable errors retried with exponential backoff, logged
- [ ] CHK049 **Diagnostic Tags**: Features tagged consistently (e.g., `[AppLaunch][FeatureName]`)

---

## ✅ Safe Refactoring & Delivery

**Reference**: `.specify/memory/constitution.md` - Section VI: Safe Refactoring & Delivery

- [ ] CHK050 **Backward Compatibility**: No breaking changes to public APIs or data contracts
- [ ] CHK051 **Migration Path**: If data schema changed, migration logic documented
- [ ] CHK052 **Downstream Impact**: Changes reviewed for impact on other features
- [ ] CHK053 **Rollback Plan**: In case of critical issue, rollback documented
- [ ] CHK054 **Code Review**: Feature PR reviewed for architecture, testing, performance
- [ ] CHK055 **Documentation**: README or inline docs explain architecture, testing approach, known limitations

---

## Notes

- Check items off as completed: `[x]`
- Add comments inline if assumptions or waivers needed
- Link to specific test files or documentation
- Flag any constitution violations with justification (see Complexity Tracking in plan.md)
