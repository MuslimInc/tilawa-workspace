# Feature Specification: Home Dashboard

**Feature Branch**: `022-home-dashboard`  
**Created**: 2026-06-15  
**Status**: Draft  
**Input**: First-class premium-feeling Home screen inspired by Sadiq, with
profile, location, next prayer, Today Plan, and feature shortcuts.

## User Scenarios & Testing

### Primary User Story

As a Tilawa user, I want the app to open to a calm daily dashboard so I can see
my next prayer, continue my Quran routine, and reach the main app features
without deciding where to start.

### Acceptance Criteria

1. **Given** the user opens Tilawa, **When** the main shell appears, **Then** the
   Home tab is selected first.
2. **Given** prayer location is saved or recently resolved, **When** Home loads,
   **Then** it shows the location label, next prayer name, time, and countdown.
3. **Given** prayer location is unavailable, **When** Home loads, **Then** it
   shows a non-blocking prompt to set location and does not request permission
   without user intent.
4. **Given** Today Plan is available, **When** Home loads, **Then** it appears as
   the primary daily engagement module.
5. **Given** the user taps quick actions, **When** they choose Quran, reciters,
   prayer, qibla, athkar, or settings, **Then** the app routes to the matching
   experience.

## Requirements

- Home MUST be the first shell tab and the default selected tab.
- Home MUST compose existing domain features instead of duplicating reciter,
  prayer, or Today Plan state.
- Passive Home load MUST NOT open OS location permission prompts.
- Home MUST remain useful when offline, anonymous, or missing location.
- The UI MUST follow Tilawa design tokens, RTL, and minimum touch targets.
- Reciters MUST remain reachable from Home and existing reciter routes.
- Bottom navigation MUST expose Home, Prayer, Quran, Athkar, and Settings.

## MVP Scope

- Profile greeting using the current authenticated user when available.
- Saved/last-resolved prayer location chip.
- Next prayer card with countdown.
- Today Plan card.
- Explore grid for Quran, reciters, prayer, qibla, athkar, and settings.
- Calm daily ayah/dua content cards as non-interactive retention surfaces.

## Out of Scope

- Remote personalized home feed.
- Server sync for home layout.
- Premium monetization placement beyond Today Plan.
- Full prayer timeline redesign.
