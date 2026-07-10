# Quran Sessions — Admin Configuration & Operations

## Overview
This document outlines the administrative configuration capabilities for Quran Sessions. Operations and settings are managed through the Tilawa Admin Panel (Angular) and backed by secure Firebase Cloud Functions.

## Configuration Hierarchy

Configurations flow through a hierarchy from Global → Market → Teacher:

1. **Global Platform Settings** (`quran_session_platform_config/global`)
   - Feature flags: Enable/disable core modules (Quran Sessions, Student Entry, Booking).
   - Global defaults: `sessionMode`, `bookingMode`, `joinWindowLeadMs`, `tutorApprovalSlaMs`, `minBookingNoticeMs`, `maxConcurrentUpcomingPerStudent`.
   - Modifiable via the **Global Settings** page in the Admin Panel.

2. **Market Config Overrides** (`quran_session_market_configs/{countryCode}`)
   - Pricing bounds (base minSessionPrice) and Currency.
   - Market-specific policies: `paymentProviderEnabled`, `genderMatchingEnabled`, overriding global defaults for `sessionMode`, `bookingMode`, `joinWindowLeadMs`, `tutorApprovalSlaMs`, `minBookingNoticeMs`, `maxConcurrentUpcomingPerStudent`.
   - Modifiable via the **Market Pricing** page in the Admin Panel.
   - **Important:** Payment is fail-closed. If `paymentProviderEnabled` is false for a market, users cannot initiate checkout flows for teachers in that market. Do not enable until Stripe/Paymob accounts are properly linked and verified.

3. **Teacher Pricing Preferences** (`quran_teacher_profiles/{teacherId}/pricing/{countryCode}`)
   - Teacher-specific rate within the market's min/max bounds.
   - Inherits policies from Market and Global config.

## Admin Tools

### 1. Global Settings Page
Located at `/quran-sessions/global-settings`.
Use this to manage the master kill-switches and platform-wide defaults.

### 2. Market Pricing Page
Located at `/quran-sessions/market-pricing`.
Use this to configure individual countries (e.g., EG, SA, AE) and their cities. You can enable payments here and specify unique policy overrides for that market.

### 3. Resolved Config Inspector
Located at `/quran-sessions/resolved-config-inspector`.
A diagnostic tool to determine exactly which policies apply to a specific Student and Teacher interaction. It calls the `getResolvedSessionConfig` Firebase function to output the merged configuration tree (Global → Market → Teacher), resolving feature flags and payment provider status securely on the backend.

### 4. Create Test Session
Located at `/quran-sessions/create-test-session`.
Allows QA and Admins to bypass normal scheduling constraints to instantly create sessions between specified students and teachers. Extremely useful for verifying video infrastructure and report workflows in Staging.
