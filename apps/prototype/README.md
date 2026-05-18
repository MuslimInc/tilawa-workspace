# Tilawa JSX Prototype

This folder contains a static React prototype for exploring the Tilawa app
experience outside the Flutter runtime.

## Files

- `TilawaAppPrototype.jsx` - React component tree for the app shell, Quran
  reader card, prayer context, reciter panel, qibla state, and expanded audio
  player.
- `tilawa_app_prototype.css` - CSS token mapping based on Tilawa UI Kit
  foundations: brand teal, sage, muted gold, neutral surfaces, 8dp spacing,
  8-24px radii, subtle outlines, and glass player surfaces.

## Design Notes

- Uses calm, non-figurative Islamic geometry instead of stock imagery.
- Keeps Quran content inside the reader surface, not as decoration.
- Mirrors UI Kit component roles: adaptive shell, cards, chips, icon buttons,
  illustrated state, glass panel, seek bar, and player background layer.
- Includes responsive behavior for desktop, tablet, and compact mobile widths.
