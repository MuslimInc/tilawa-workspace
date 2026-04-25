# Data Model: Custom Player Background

## Entities

### PlayerBackgroundConfiguration
Represents the user's background preference for the expanded audio player.

| Field | Type | Description |
|-------|------|-------------|
| type | Enum | `default` or `custom` |
| customImagePath | String? | Absolute path to the locally stored image file |
| blurAmount | Double | Intensity of the blur effect (default: 0.0) |
| overlayOpacity | Double | Opacity of the darkening overlay (default: 0.4) |

## State Transitions

### BackgroundState
- `initial`: Using default theme background.
- `selecting`: Picker/Camera is open.
- `processing`: Copying image to internal storage and optimizing.
- `custom`: Using custom image background.
- `error`: Failed to pick or process image (fallback to default).

## Persistence
The `PlayerBackgroundConfiguration` will be serialized to JSON and stored via `HydratedCubit`.
Images will be stored in `(App Documents)/player_backgrounds/custom_bg_[timestamp].jpg`.
Only the current active image will be kept; old custom backgrounds should be cleaned up on new selection.
