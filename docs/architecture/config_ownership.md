# Configuration Ownership and Feature Flags

This document outlines the separation of concerns and ownership strategy for configuration and feature flags across the Tilawa platform.

## Architecture Overview

The system uses three distinct layers of configuration to control application behavior:

1. **Compile-Time Launch Flags (AppLaunchConfig)**
2. **Runtime Admin/Firestore Config (PlatformConfig)**
3. **Backend Environment Flags (Cloud Functions / Firebase Env)**

### 1. Compile-Time Launch Flags (`AppLaunchConfig`)
- **What they are:** Flags defined using `--dart-define` or `--dart-define-from-file` in `env/*.json` and `launch.json`.
- **Ownership:** Developer / CI.
- **Update Mechanism:** Requires a full **application rebuild** to change.
- **Use Cases:** 
  - Build/infra settings (e.g., pointing to local vs staging APIs).
  - Enabling experimental dev-only features (e.g., hybrid flags like `deviceRegistryWriteEnabled` or `multiDeviceLoginEnabled`).
  - Flags interacting with third-party SDK initialization keys (e.g., `agoraAppId`).

### 2. Runtime Admin/Firestore Config (`PlatformConfig`)
- **What they are:** Remote configuration documents read directly from Firestore at runtime. For example, `QuranSessionsPlatformConfig`.
- **Ownership:** Product Managers / Admins.
- **Update Mechanism:** **Live**. Changes made in the Admin Panel or directly in Firestore propagate to the app instantly without a rebuild or redeploy.
- **Use Cases:**
  - Enabling/disabling product features (e.g., `quranSessionsEnabled`, `teacherApplicationEntryEnabled`).
  - Modifying business rules, pricing strategies, and dynamically toggling UI components (e.g., `teacherApplicationDiscoverability`).
  
### 3. Backend Environment Flags
- **What they are:** Environment variables configured in Firebase Cloud Functions (`.env` files).
- **Ownership:** Backend / DevOps.
- **Update Mechanism:** Requires a **Cloud Functions redeploy**.
- **Use Cases:** 
  - Source of truth for pricing, bookability, and business transactions.
  - Controlling backend behavior securely.
  - Payment, wallet, and critical external integrations.

---

## The "Orphaned Flags" Cleanup

Historically, Quran Sessions had flags scattered across both compile-time (`AppLaunchConfig`) and runtime (`PlatformConfig`) configurations. This dual-state ownership created confusion:

- If a developer disabled it in `launch.json`, an admin couldn't enable it.
- If it was an admin-level feature, it shouldn't require an app release to toggle.

**Why the launch flags were safe to remove:**
All product-level features for Quran Sessions are now fully governed by `QuranSessionsPlatformConfig`. An audit confirmed that fields like `quranSessionsEnabled`, `learnQuranStudentFeatureEnabled`, `teacherApplicationEnabled`, `quranSessionsBookingEnabled`, etc., within `AppLaunchConfig` had **zero direct readers**. Therefore, they were safely deleted.

**Intentionally Kept Compile-Time/Hybrid Flags:**
Some flags remain in `AppLaunchConfig` because they impact fundamental app startup behavior or development testing environments:
- `teacherDashboardSummaryReadEnabled`
- `deviceRegistryWriteEnabled`
- `multiDeviceLoginEnabled`
- `teacherApplicationFormUrl` (fallback)
- `agoraAppId`, `livekitServerUrl`, `genUiAssistantEnabled`

This cleanup reinforces the pattern that **product capabilities are governed by runtime admin config**, whereas **app wiring and developer tools belong to compile-time config**.
