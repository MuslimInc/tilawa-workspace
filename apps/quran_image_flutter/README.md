# Quran Image Flutter

A Flutter Quran reader app using pre-rendered ayah images for optimal performance.

## Features

- **Image-based rendering**: Uses pre-rendered PNG images for each ayah (verse) instead of text rendering
- **Zero text layout overhead**: No font loading, shaping, or rasterization during scroll
- **Smooth 120 FPS scrolling**: Pure image blitting with GPU acceleration
- **604 pages**: Full Quran with page navigation

## Setup

1. Copy Quran images from `ayah_app_assets`:

```bash
chmod +x copy_assets.sh
./copy_assets.sh
```

2. Run the app:

```bash
flutter run
```

## Performance Benefits

Compared to text-based rendering:
- **No font loading**: Images are ready immediately
- **No layout passes**: No text measurement or shaping
- **No rasterization**: Images are pre-rasterized
- **GPU-only rendering**: Simple texture blitting

## TODO

- [ ] Add proper page-to-surah/ayah mapping for all 604 pages
- [ ] Add page cache management (keep ±2 pages in memory)
- [ ] Add zoom and pan gestures
- [ ] Add dark mode support
