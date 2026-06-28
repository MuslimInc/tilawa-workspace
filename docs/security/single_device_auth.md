# Single-Device Authentication

Tilawa enforces one active device per account. An explicit sign-in on a new
device may replace the active device; passive startup, token refresh, resume,
and background sync may not replace it.

## Data Collected

The active device registration stores:

- app-scoped device identifier: Firebase Installations ID, or a local
  `local_<random_hex>` fallback when FID is unavailable
- FCM token for push notifications
- platform
- OS name and version
- device model and manufacturer
- app version and build number
- session epoch metadata

## Purpose

This data is used for:

- account security
- single-device enforcement
- push notification delivery
- support and debugging

## Excluded Identifiers

Tilawa does not collect IMEI, serial number, MAC address, advertising ID,
Android hardware ID, phone number, or other hardware identifiers for
single-device authentication.
