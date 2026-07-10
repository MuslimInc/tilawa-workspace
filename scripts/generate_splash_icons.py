#!/usr/bin/env python3
"""Generate splash icon PNGs from memuslim_logo_splash.svg.

Android 12+ SplashScreen (icon without background): the icon drawable is
rendered on a 288 dp canvas and the system masks it to a 192 dp circle
(inner 2/3). For the mark to avoid the enlarged Android 12 look while
surviving the circular mask, its bounding-box DIAGONAL must sit comfortably
inside that circle — not just its width/height.

Master frame: 1152 px == 288 dp @4x. Safe circle: 768 px == 192 dp @4x.
The book bbox is measured from the rendered alpha channel, then scaled so
diagonal == safe-circle diameter × MARK_SAFE_FRACTION, and centered on the
frame.

Flutter shows the SAME full-frame master in a 288 dp box
(`LaunchSplashContent.logoBoxSize == AppColors.launchSplashLogoFrameSize`),
so the native → Flutter handoff renders the mark at identical visible size.

Usage:  python3 scripts/generate_splash_icons.py
Needs:  node (npx @resvg/resvg-js-cli), Pillow.
"""

import math
import subprocess
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SVG = ROOT / "docs/design/app_logo/memuslim_logo_splash.svg"
RES = ROOT / "apps/tilawa/android/app/src/main/res"
FLUTTER_ASSET = ROOT / "apps/tilawa/assets/images/app_logo.png"

FRAME_PX = 1152  # 288 dp @ 4x (xxxhdpi master)
SAFE_PX = 768  # 192 dp @ 4x — Android 12+ visible mask circle
MARK_SAFE_FRACTION = 0.72

# Android 12+ icon frame is 288 dp; one PNG per density bucket.
DENSITIES = {
    "mdpi": 288,
    "hdpi": 432,
    "xhdpi": 576,
    "xxhdpi": 864,
    "xxxhdpi": 1152,
}

RENDER_BASE = 1600  # oversampled render used to measure + scale the mark


def render_svg(size: int) -> Image.Image:
    with tempfile.NamedTemporaryFile(suffix=".png") as tmp:
        subprocess.run(
            [
                "npx",
                "--yes",
                "@resvg/resvg-js-cli",
                "--fit-width",
                str(size),
                str(SVG),
                tmp.name,
            ],
            check=True,
            capture_output=True,
        )
        return Image.open(tmp.name).convert("RGBA")


def build_master() -> Image.Image:
    art = render_svg(RENDER_BASE)
    bbox = art.getbbox()
    if bbox is None:
        raise SystemExit(f"empty render from {SVG}")
    mark = art.crop(bbox)

    diagonal = math.hypot(mark.width, mark.height)
    scale = SAFE_PX * MARK_SAFE_FRACTION / diagonal
    new_w = round(mark.width * scale)
    new_h = round(mark.height * scale)
    mark = mark.resize((new_w, new_h), Image.Resampling.LANCZOS)

    frame = Image.new("RGBA", (FRAME_PX, FRAME_PX), (0, 0, 0, 0))
    frame.paste(mark, ((FRAME_PX - new_w) // 2, (FRAME_PX - new_h) // 2), mark)

    print(
        f"mark {new_w}×{new_h}px in {FRAME_PX}px frame "
        f"(diagonal {math.hypot(new_w, new_h):.0f} ≤ safe {SAFE_PX})"
    )
    return frame


def main() -> None:
    master = build_master()

    for bucket, size in DENSITIES.items():
        out_dir = RES / f"drawable-{bucket}"
        out_dir.mkdir(parents=True, exist_ok=True)
        out = master.resize((size, size), Image.Resampling.LANCZOS)
        out.save(out_dir / "splash_icon_bitmap.png")
        print(f"wrote drawable-{bucket}/splash_icon_bitmap.png ({size}px)")

    master.save(FLUTTER_ASSET)
    print(f"wrote {FLUTTER_ASSET.relative_to(ROOT)} ({FRAME_PX}px)")


if __name__ == "__main__":
    main()
