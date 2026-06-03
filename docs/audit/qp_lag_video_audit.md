# qp_lag.webm — frame audit (2026-06-03)

Source: `screenshots/videos/qp_lag.webm` (1080×2400, ~81.5s, 24fps).

Frames extracted at **4 fps**, width **360** → `screenshots/videos/qp_lag_frames/` (326 images).

Re-run analysis:

```sh
python3 apps/tilawa/tool/analyze_qp_lag_video.py
```

## UI layers observed

| Time (approx) | Screen | Layers (back → front) |
|---------------|--------|-------------------------|
| 0–10s | Settings | Scaffold → profile card → settings groups → **language bottom sheet** → bottom nav |
| 10–25s | Expanded player | Shell scrim → expanded sheet → **stage** (art + metadata scroll) → playback cluster → **queue `DraggableScrollableSheet`** |
| 25–45s | Player interactions | Queue sheet resize, queue-focused stage, compact bar transitions |
| 42–44s | Large spikes | Settings sheet open/close or full player layout swap |
| 59–61s | Largest spikes | Queue-focused layout ↔ default stage (artwork vs history list) |

## Frame-diff spikes (jank proxy)

Median frame-to-frame diff ≈ **4.8** (RGB 0–255 scale). Spikes ≥ **12** indicate abrupt visual change (not smooth 60fps motion).

Notable spikes:

| Time | Δ | Likely cause |
|------|---|----------------|
| **60.5s** | **110** | Queue-focused ↔ default stage layout swap |
| **59.5s** | **97** | Same transition (opposite direction) |
| **43.3s** | **89** | Modal / route / sheet transition |
| **42.0s** | **87** | Settings language sheet or player mode change |
| 8–27s | 30–40 | Collapse/expand drag, opacity path flips, queue sheet motion |

## Root causes (code)

1. **Metrics path flip** — During collapse drag, `collapseBiased` switched from expand-forward interactive metrics to full collapse metrics in one frame → mini/sheet/handoff jumped (`PlayerExpandTransitionMetrics.compute`).
2. **Organism desync** — `_ExpandedPlayerOrganism` recomputed metrics with default `compute()` instead of `PlayerExpandMetricsScope`, so **queue chrome** and **stage** used different `queueChromeT` / opacities than the shell overlay.
3. **Gesture exceptions** — `DragEndDetails` velocity mismatch and `setState` after dispose on `QuranPlayerExpandedStageCollapsibleScrollRegion` interrupted collapse animation.

## Tests added (regression)

- `test/shared/widgets/quran_player_animation_stability_test.dart`
- `lib/shared/widgets/quran_player_animation_stability.dart`

Assertions:

- Monotonic collapse drag progress
- No metric step Δ > 0.18 on simulated collapse timeline (10px drag steps)
- `sheetMotionT` tracks finger progress during interactive collapse
- No `miniOpacity` jump at collapse-anchor flip

## Fixes shipped

- Blended interactive collapse metrics (`interactiveCollapseAnchor`)
- Ramped morph/handoff during drag (`_interactiveCollapseMorphBlend`)
- Organism uses `PlayerExpandMetricsScope.maybeOf(context)` for queue/stage layout
- Prior: collapsible scroll region, `DragEndDetails` sanitizer, dispose-safe pointer end
