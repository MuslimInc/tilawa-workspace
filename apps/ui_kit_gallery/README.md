# Tilawa UI Kit Gallery

Interactive catalog of every public component in `packages/ui_kit`.

## Run

From the workspace root:

```bash
cd apps/ui_kit_gallery
flutter run
```

Or target a device:

```bash
flutter run -d macos
flutter run -d chrome
```

## Features

- Browse **Atoms**, **Molecules**, and **Organisms** in one list
- Search components by name
- Per-screen **light/dark** and **LTR/RTL** toggles
- Live demos with interactive state where needed (switches, segmented controls, adaptive shell)

## Adding a component

1. Add a demo builder in `lib/gallery/demos/`.
2. Register a `GalleryEntry` in `lib/gallery/gallery_catalog.dart`.
