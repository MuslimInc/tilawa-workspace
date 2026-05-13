# Google Play Screenshot Readiness

This guide defines the store screenshot direction for Tilawa after the premium
state-system work. It is intentionally conservative: no random images, no
childish illustration, no decorative Quranic text, and no visuals that compete
with Quran readability or prayer accuracy.

## Current Inventory

Raw captures already exist at `1344x2992` for English and Arabic:

- `screenshots/raw/en/en_01_prayer_times.png`
- `screenshots/raw/en/en_02_adhan_settings.png`
- `screenshots/raw/en/en_03_quran_reader.png`
- `screenshots/raw/en/en_04_reciters.png`
- `screenshots/raw/en/en_05_offline_downloads.png`
- `screenshots/raw/en/en_06_athkar.png`
- `screenshots/raw/en/en_07_qibla.png`
- `screenshots/raw/ar/ar_01_prayer_times.png`
- `screenshots/raw/ar/ar_02_adhan_settings.png`
- `screenshots/raw/ar/ar_03_quran_reader.png`
- `screenshots/raw/ar/ar_04_reciters.png`
- `screenshots/raw/ar/ar_05_offline_downloads.png`
- `screenshots/raw/ar/ar_06_athkar.png`
- `screenshots/raw/ar/ar_07_qibla.png`

Final framed output currently exists only for:

- `screenshots/final/en/play_en_01_prayer_times_1080x1920.png`

The existing builder is:

- `screenshots/tools/build_play_sample_en_01.py`

## Storyboard

Use seven screenshots. The sequence should tell a calm product story, not a
feature checklist.

| Slot | Screen | Primary message | Visual priority |
|------|--------|-----------------|-----------------|
| 1 | Prayer Times | Prayer times and Adhan you can trust | Trust, daily utility, calm first impression |
| 2 | Adhan Settings | Personalize prayer reminders | Control, clarity, respectful settings |
| 3 | Quran Reader | Read Quran with focused clarity | Sacred content, no extra decoration |
| 4 | Reciters | Listen to beautiful recitations | Discovery, breadth, human warmth through names |
| 5 | Offline Downloads | Keep recitations ready offline | Reliability, travel, low-connectivity value |
| 6 | Athkar | Daily remembrance, gently organized | Spiritual habit, minimal warmth |
| 7 | Qibla | Find Qibla with confidence | Direction, permission clarity, trust |

## Headline Rules

- Keep headlines under two lines on `1080x1920`.
- Use plain benefit language, not marketing exaggeration.
- Do not use Quranic text or sacred phrases as decorative headline content.
- Mirror the same meaning in Arabic, but do not force literal word-for-word
  translation when it harms natural phrasing.
- Avoid feature labels that duplicate the visible app bar unless the benefit is
  unclear.

Recommended English headline set:

- Prayer times and Adhan you can trust
- Personalize reminders for every prayer
- Read Quran with focused clarity
- Reciters from across the Muslim world
- Keep recitations ready offline
- Daily Athkar, calmly organized
- Find Qibla with confidence

## Visual Treatment

Use the existing Play frame style as the baseline:

- Final output: `1080x1920`.
- Soft neutral background with subtle depth.
- Physical phone frame, slim bezel, no heavy dark device mockup.
- App screenshot remains the hero.
- No decorative stock photography.
- No extra icons outside the app screenshot unless a future reviewed template
  explicitly adds them.

Follow `packages/ui_kit/docs/premium_visual_system.md` for the in-app visual
language. The screenshot wrapper may add light editorial polish, but the app
UI itself must remain the source of truth.

## Capture States

Use realistic, populated states for store screenshots:

- Prayer Times: loaded state with current location visible.
- Adhan Settings: notification controls visible, no debug-only rows.
- Quran Reader: readable page, no overlays blocking text.
- Reciters: populated list, search not active unless showing discovery.
- Downloads: populated offline library when possible. If using an empty state,
  it must show the premium `TilawaIllustratedState` visual and the Reciters CTA.
- Athkar: useful categories or tasbeeh state, not a dead empty surface.
- Qibla: success compass state preferred. Permission/error state is acceptable
  only for a support/help screenshot, not the main store sequence.

## Locale Requirements

Build English and Arabic sets separately:

- English output path: `screenshots/final/en/`.
- Arabic output path: `screenshots/final/ar/`.
- Arabic screenshots must use RTL app chrome and natural Arabic headlines.
- Do not reuse English-framed screenshots for Arabic listing assets.

## QA Checklist

Before uploading to Google Play:

- [ ] Every final image is `1080x1920`.
- [ ] English and Arabic sets have matching slot order.
- [ ] No raw emulator status strip, punch hole, or black rounded corners remain.
- [ ] No text is clipped inside the app screenshot or the headline.
- [ ] Quran reader screenshot has no headline or frame element covering Quran
      text.
- [ ] App UI uses production data and no debug banners.
- [ ] Empty, loading, permission, or error states are used only when they tell a
      clear product story.
- [ ] Screenshots remain readable at Play Console thumbnail size.
- [ ] File names follow `play_{locale}_{slot}_{screen}_1080x1920.png`.

## Implementation Notes

When expanding the screenshot builder:

- Keep crop and framing constants centralized.
- Keep per-slot headline data in a structured map rather than copy-pasting
  scripts.
- Preserve the existing raw screenshot files unless replacing them with newer
  captures from the app.
- Review generated output visually before committing final PNGs.

Current builder:

```shell
python3 screenshots/tools/build_play_screenshots.py
```
