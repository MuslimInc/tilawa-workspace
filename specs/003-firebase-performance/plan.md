# Firebase Performance Monitoring Implementation Plan

## Overview
Implement Firebase Performance Monitoring following Clean Architecture, KISS, DRY, SOLID, and YAGNI principles. Start minimal, add only what proves necessary.

## Architecture

### Layer Structure
```
┌─────────────────────────────────────────────────────────┐
│  apps/tilawa/                                           │
│  ├── lib/core/services/firebase_performance_service.dart │
│  └── lib/core/di/performance_module.dart                │
├─────────────────────────────────────────────────────────┤
│  packages/core/lib/                                     │
│  ├── services/performance_monitoring_service.dart       │
│  └── services/performance_trace.dart                    │
└─────────────────────────────────────────────────────────┘
```

## Implementation Steps

### 1. Domain Layer (packages/core)

#### 1.1 Create PerformanceMonitoringService Interface
**File:** `packages/core/lib/services/performance_monitoring_service.dart`

**Purpose:** Abstract contract for performance monitoring following Dependency Inversion Principle.

**Key Methods (YAGNI: start with 3):**
- `Future<T> traceOperation<T>(String name, Future<T> Function() operation)` - Auto-instrument operations (primary use case)
- `PerformanceTrace? startTrace(String name)` - Manual trace, returns nullable (no-op in debug)
- `void setEnabled(bool enabled)` - Toggle collection (debug builds)

**KISS:** No HTTP-specific methods - Firebase auto-captures HTTP. No global attributes - use trace-level only.

**Principles:**
- **KISS:** 2-method interface, no complex configuration
- **SRP:** Contract definition only
- **ISP:** Minimal surface (2 methods)
- **DIP:** High-level modules depend on this abstraction

#### 1.2 Create PerformanceTrace Abstract Class
**File:** `packages/core/lib/services/performance_trace.dart`

**Purpose:** Abstract trace handle for granular timing control.

**Methods (minimal surface):**
- `void stop()` - End trace and send to Firebase
- `void putAttribute(String name, String value)` - One attribute method (metrics = attributes with numeric values as strings)

**DRY:** Single `putAttribute` handles all data - Firebase converts numeric strings to metrics automatically.

**Principles:**
- **KISS:** Simple interface, no generics, no complex types
- **OCP:** Extendable without consumer changes
- **DIP:** Consumers depend on abstraction

---

### 2. Data Layer (apps/tilawa)

#### 2.1 Create FirebasePerformanceService Implementation
**File:** `apps/tilawa/lib/core/services/firebase_performance_service.dart`

**Pattern:** Same as `FirebaseAnalyticsService` - singleton registration.

**Features (YAGNI-compliant):**
- Debug build auto-disable via constructor flag
- Error-safe: all methods swallow exceptions (monitoring never breaks features)
- **NO validation:** Firebase SDK validates names, let it reject if needed
- **NO limit enforcement:** Firebase handles limits, trust the SDK

**Implementation Details:**
```dart
@Singleton(as: PerformanceMonitoringService)
class FirebasePerformanceService implements PerformanceMonitoringService {
  FirebasePerformanceService(this._performance) {
    if (kDebugMode) _performance.setPerformanceCollectionEnabled(false);
  }
  
  // Trace naming: /^[a-zA-Z][a-zA-Z0-9_]*$/
  // Max length: 100 characters
}
```

**Principles:**
- **SRP:** Delegates to Firebase SDK only
- **OCP:** New backends = new files, no changes here
- **LSP:** Mock service fully substitutable
- **DRY:** Reuses existing `kDebugMode` pattern from `FirebaseAnalyticsService`

#### 2.2 Create PerformanceModule for DI Registration
**File:** `apps/tilawa/lib/core/di/performance_module.dart`

**Purpose:** Register Firebase Performance instance as injectable dependency.

```dart
@module
abstract class PerformanceModule {
  @singleton
  FirebasePerformance get performance => FirebasePerformance.instance;
}
```

---

### 3. Integration Points (YAGNI - Phase 1 only)

#### 3.1 Manual Traces Only (Start Here)
**Files:** Critical operations only

**KISS:** No automatic screen traces initially - Firebase captures these automatically via native SDK. Only add custom traces for:
- Quran page download operations
- Audio loading latency

**DRY:** Don't build a route observer - Firebase SDK already traces screen rendering.

#### 3.2 Quran Image Cache Monitoring (Phase 1)
**File:** Callback injection into `quran_image` package

**Single trace:** `download_pages` with attribute `page_count` - don't trace individual pages (604 traces/page = too noisy)

**YAGNI:** No image decode tracing - file I/O is the bottleneck, not PNG decode.

#### 3.3 Audio Playback Tracing (Phase 2 - only if Phase 1 shows need)
**File:** `apps/tilawa/lib/shared/audio/audio_player_handler_impl.dart`

**Single trace:** `audio_load` with attributes `reciter_id`, `surah_id`

**YAGNI:** Skip buffer/seek tracing unless `audio_load` shows >2s duration in console.

#### 3.4 API Call Monitoring (YAGNI)
**Skip entirely** - Firebase Performance auto-captures HTTP requests from native level. No custom interceptor needed.

**KISS:** Let Firebase SDK handle HTTP monitoring automatically.

---

### 4. Utility Components (YAGNI - Skip)

**No mixins.** No code generation. Use inline `traceOperation()` calls only.

**KISS:**
```dart
// Instead of mixin, just wrap operations:
await performance.traceOperation('heavy_task', () async {
  return await doHeavyWork();
});
```

---

## File List

| File | Purpose | Lines (est) |
|------|---------|-------------|
| `packages/core/lib/services/performance_monitoring_service.dart` | Interface | ~20 |
| `packages/core/lib/services/performance_trace.dart` | Trace abstraction | ~15 |
| `apps/tilawa/lib/core/services/firebase_performance_service.dart` | Implementation | ~80 |
| `apps/tilawa/lib/core/di/performance_module.dart` | DI module | ~10 |

**YAGNI:** Skip route observer (Firebase auto-captures screens), skip HTTP interceptor (auto-captured).

---

## Testing Strategy

### Unit Tests
1. **MockPerformanceService** implements interface for testing
2. Verify trace start/stop calls
3. Attribute/metric limit enforcement
4. Error handling (service never throws)

### Integration Tests
1. Verify Firebase receives traces (using Firebase console debug view)
2. Screen navigation traces
3. HTTP metrics for API calls

---

## Firebase Console Configuration

### Custom Traces to Monitor
| Trace Name | Trigger | Attributes |
|------------|---------|------------|
| `screen_quran_reader` | Reader screen visible | page_number, reciter_id |
| `download_page_batch` | Page download operation | pages_count, success_rate |
| `audio_load` | Play button tapped | reciter_id, surah_id |
| `prayer_times_calculation` | Prayer times computed | location_method, calc_method |

### HTTP URL Patterns
- `https://firebasestorage.googleapis.com/**` - Audio file downloads
- `https://**.cloudfunctions.net/**` - API calls
- `https://**.r2.cloudflarestorage.com/**` - Quran image CDN

---

## Principles Compliance

| Principle | Implementation |
|-----------|-----------------|
| **K**eep **I**t **S**imple, **S**tupid | 2-method interface, no validation logic, Firebase SDK handles limits |
| **D**on't **R**epeat **Y**ourself | Reuses debug-mode pattern from Analytics, single attribute method |
| **S**ingle Responsibility | Interface = contract, Impl = Firebase delegation |
| **O**pen/Closed | New backends = new files |
| **L**iskov Substitution | Mock service fully substitutable |
| **I**nterface Segregation | 2 methods only, no HTTP-specific surface |
| **D**ependency Inversion | Domain depends on abstractions |
| **Y**ou **A**in't **G**onna **N**eed **I**t | No route observer, no HTTP interceptor, no mixins, no decorators (Phase 1)

---

## Dependencies

```yaml
# Already present:
# - firebase_core: ^4.3.0

# To add:
firebase_performance: ^0.11.3
```

---

## Rollout Plan (YAGNI - Phased)

1. **Phase 1 (Now):** Core interface + Firebase implementation + 1-2 manual traces (Quran download, audio load)
2. **Phase 2 (After data review):** Add traces only if console shows blind spots (screen traces are auto-captured, check first)
3. **Phase 3 (Never if not needed):** Route observers, mixins, decorators only if manual traces insufficient

**Decision gate:** Review Firebase console after 1 week of Phase 1. Only add Phase 2/3 if metrics gaps exist.
