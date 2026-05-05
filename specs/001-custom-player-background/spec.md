# Feature Specification: Custom Player Background

**Feature Branch**: `001-custom-player-background`  
**Created**: 2026-04-25  
**Status**: Released — v0.1.4+21 (2026-04-27)  
**Input**: User description: "Now, plan for a new feature that allow user to change the background of bottom prayer when expanded from his gallery or take a camera picture"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Personalize with Gallery Image (Priority: P1)

As a user, I want to select an image from my phone's gallery and set it as the background of the expanded audio player so that I can personalize my listening experience with my favorite photos or wallpapers.

**Why this priority**: Personalization is a core request for enhancing user engagement and making the app feel more "theirs".

**Independent Test**: Can be fully tested by opening the player, choosing "Change Background", selecting an image from the gallery, and verifying the expanded player background updates.

**Acceptance Scenarios**:

1. **Given** the audio player is expanded, **When** I tap the "Change Background" option and select "Gallery", **Then** the system opens the device's image picker.
2. **Given** an image is selected from the gallery, **When** I return to the player, **Then** the background of the expanded player is updated with the selected image.

---

### User Story 2 - Capture Moment with Camera (Priority: P1)

As a user, I want to take a new photo using my camera and immediately set it as the player background to capture a current mood or environment.

**Why this priority**: Provides an immediate and creative way to change the UI without leaving the app.

**Independent Test**: Can be fully tested by selecting "Camera", taking a photo, and verifying the background update.

**Acceptance Scenarios**:

1. **Given** the audio player is expanded, **When** I select "Take Photo", **Then** the system opens the camera interface.
2. **Given** a photo is captured, **When** the photo is confirmed, **Then** the player background reflects the new image immediately.

---

### User Story 3 - Persistent Customization (Priority: P2)

As a user, I want my selected background to remain active even after I close and reopen the app so that I don't have to re-select it every time.

**Why this priority**: Critical for a good user experience; transient settings are frustrating.

**Independent Test**: Set a background, restart the app, and verify the background is still applied.

**Acceptance Scenarios**:

1. **Given** a custom background is set, **When** the app is terminated and restarted, **Then** the expanded player still shows the same custom background.

---

### User Story 4 - Reset to Default (Priority: P3)

As a user, I want to be able to remove my custom background and revert to the original theme-based background.

**Why this priority**: Users need a way to undo changes if they no longer like the custom image.

**Independent Test**: Apply a background, select "Reset", and verify the original UI is restored.

**Acceptance Scenarios**:

1. **Given** a custom background is active, **When** I select "Reset to Default", **Then** the custom image is removed and the original design returns.

---

### Edge Cases

- **Permission Denied**: What happens if the user denies camera or gallery permissions? (System MUST show a clear message and instructions to enable in settings).
- **Invalid Image**: What if the selected file is corrupted or not an image? (System MUST handle gracefully with an error toast).
- **Low Memory**: How does high-resolution background loading affect performance on older devices? (System SHOULD downscale or optimize image before setting as background).
- **App Storage**: If the original gallery image is deleted, does the player lose its background? (System SHOULD copy the selected image to the app's internal storage).
- **Dark/Light Mode**: How does the custom image interact with UI text readability? (System SHOULD apply a subtle dark/light overlay to ensure text remains legible).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a "Change Background" trigger within the expanded audio player UI.
- **FR-002**: System MUST support image selection via the native device gallery/file picker.
- **FR-003**: System MUST support image capture via the native camera interface.
- **FR-004**: System MUST handle runtime permission requests for `CAMERA` and `PHOTO_LIBRARY`.
- **FR-005**: System MUST persist the chosen image by copying it to the application's secure storage directory.
- **FR-006**: System MUST automatically apply a legibility overlay (e.g., blur or darkened gradient) over the custom background.
- **FR-007**: System MUST provide a "Reset to Default" option to clear custom backgrounds.
- **FR-008**: The custom background MUST only be visible when the player is in its expanded state.

### Key Entities *(include if feature involves data)*

- **PlayerBackgroundConfiguration**: Entity representing the state of the player background (type: default/custom, localPath, overlayIntensity).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can successfully change their background in fewer than 3 taps once the picker is open.
- **SC-002**: The expanded player opens with the custom background in under 200ms (no perceptible delay due to image loading).
- **SC-003**: Zero crashes reported due to memory overflow when loading 4K+ images (ensure downscaling).

## Assumptions

- We will use standard Flutter plugins for image picking and camera access.
- The `QuranPlayerWidget` (expanded state) has enough screen real estate to showcase a background without obscuring controls.
- The user's device supports at least basic image picking.
