#!/usr/bin/env python3
"""
Validate that surah name text is properly centered within the header banner.

Compares the text center (from line images) against the banner's decorative
"window" center, simulating the Flutter runtime layout to compute screen-space
offsets.

Usage:
    python validate_header_centering.py                          # Analyze page 601
    python validate_header_centering.py --page all               # Analyze all pages
    python validate_header_centering.py --page 601 --visual      # Generate overlay images
"""

import argparse
import json
import os
from pathlib import Path

import cv2
import numpy as np

SCRIPT_DIR = Path(__file__).resolve().parent
ASSETS_DIR = SCRIPT_DIR / "assets"
BANNER_PATH = ASSETS_DIR / "images" / "sura_header_banner.png"
QURAN_IMAGES_DIR = ASSETS_DIR / "quran_images"
MAPPING_PATH = SCRIPT_DIR.parent.parent / "surah_header_mapping.json"

ALPHA_THRESHOLD = 12
HEADER_SPAN_MAX = 0.35

# Flutter layout constants (from quran_image_page.dart)
BANNER_H_PADDING = 8  # EdgeInsets.symmetric(horizontal: 8)
LINE_IMG_WIDTH = 1440
BANNER_IMG_WIDTH = 2000


def detect_banner_window(banner_path: Path) -> dict:
    """Detect the ornamental window region in the header banner.

    Uses column-wise standard deviation of grayscale values. The decorative
    borders have high variance (ornamental patterns); the central window
    has low variance (mostly flat cream/white).
    """
    img = cv2.imread(str(banner_path), cv2.IMREAD_UNCHANGED)
    if img is None:
        raise FileNotFoundError(f"Cannot load banner: {banner_path}")

    gray = cv2.cvtColor(img[:, :, :3], cv2.COLOR_BGR2GRAY)
    col_std = gray.astype(np.float64).std(axis=0)

    # Smooth to avoid noise spikes
    kernel_size = 20
    kernel = np.ones(kernel_size) / kernel_size
    smoothed = np.convolve(col_std, kernel, mode="same")

    center = img.shape[1] // 2
    threshold = 30.0

    # Walk outward from center to find window edges
    left = center
    for c in range(center, 0, -1):
        if smoothed[c] > threshold:
            left = c + 1
            break

    right = center
    for c in range(center, img.shape[1]):
        if smoothed[c] > threshold:
            right = c - 1
            break

    window_center = (left + right) / 2.0
    window_width = right - left

    return {
        "left": left,
        "right": right,
        "center": window_center,
        "width": window_width,
        "center_frac": window_center / img.shape[1],
        "img_width": img.shape[1],
        "img_height": img.shape[0],
    }


def detect_text_bounds(line_path: Path) -> dict | None:
    """Detect the text bounding box in a surah header line image via alpha channel."""
    img = cv2.imread(str(line_path), cv2.IMREAD_UNCHANGED)
    if img is None or img.ndim < 3 or img.shape[2] < 4:
        return None

    alpha = img[:, :, 3]
    col_max = alpha.max(axis=0)
    tcols = np.where(col_max > ALPHA_THRESHOLD)[0]

    if len(tcols) == 0:
        return None

    text_left = int(tcols[0])
    text_right = int(tcols[-1])
    span = (text_right - text_left) / img.shape[1]

    # Only consider narrow spans as surah headers
    if span >= HEADER_SPAN_MAX:
        return None

    row_max = alpha.max(axis=1)
    trows = np.where(row_max > ALPHA_THRESHOLD)[0]

    text_center_x = (text_left + text_right) / 2.0

    return {
        "left": text_left,
        "right": text_right,
        "top": int(trows[0]),
        "bottom": int(trows[-1]),
        "center_x": text_center_x,
        "center_frac": text_center_x / img.shape[1],
        "span": span,
        "img_width": img.shape[1],
        "img_height": img.shape[0],
    }


def compute_screen_offset(
    text_center_x: float,
    window: dict,
    device_width: float,
) -> dict:
    """Compute the screen-space offset between text center and banner window center.

    In the Flutter layout:
    - Line image: Positioned(left: 0, right: 0) with fit: BoxFit.fill
      -> text_screen_x = (text_center / 1440) * deviceWidth
    - Banner: Positioned(left: 0, right: 0) + Padding(horizontal: 8) with fit: BoxFit.fill
      -> banner renders from x=8 to x=(deviceWidth-8)
      -> window_screen_x = 8 + (window_center / 2000) * (deviceWidth - 16)
    """
    text_screen_x = (text_center_x / LINE_IMG_WIDTH) * device_width
    banner_content_width = device_width - 2 * BANNER_H_PADDING
    window_screen_x = (
        BANNER_H_PADDING
        + (window["center"] / window["img_width"]) * banner_content_width
    )

    offset_px = text_screen_x - window_screen_x
    offset_pct = (offset_px / device_width) * 100

    return {
        "text_screen_x": round(text_screen_x, 2),
        "window_screen_x": round(window_screen_x, 2),
        "offset_px": round(offset_px, 2),
        "offset_pct": round(offset_pct, 3),
    }


def generate_visual_overlay(
    banner_path: Path,
    line_path: Path,
    window: dict,
    text_bounds: dict,
    screen_offset: dict,
    output_path: Path,
    device_width: float,
):
    """Generate a debug overlay image showing banner window center vs text center."""
    banner = cv2.imread(str(banner_path), cv2.IMREAD_UNCHANGED)
    line_img = cv2.imread(str(line_path), cv2.IMREAD_UNCHANGED)

    vis_width = 800
    banner_h = int(banner.shape[0] * vis_width / banner.shape[1])
    line_h = int(line_img.shape[0] * vis_width / line_img.shape[1])

    line_resized = cv2.resize(line_img, (vis_width, line_h))

    canvas_h = banner_h + line_h + 80
    canvas = np.ones((canvas_h, vis_width, 4), dtype=np.uint8) * 255
    canvas[:, :, 3] = 255

    padding_vis = int(BANNER_H_PADDING / device_width * vis_width)
    banner_vis_width = vis_width - 2 * padding_vis
    banner_fit = cv2.resize(banner, (banner_vis_width, banner_h))

    y_offset = 30
    canvas[
        y_offset : y_offset + banner_h,
        padding_vis : padding_vis + banner_vis_width,
        :,
    ] = banner_fit

    line_y = y_offset
    for r in range(line_h):
        for c in range(vis_width):
            a = line_resized[r, c, 3] / 255.0
            if a > 0.05:
                canvas[line_y + r, c, :3] = (
                    (1 - a) * canvas[line_y + r, c, :3]
                    + a * line_resized[r, c, :3]
                ).astype(np.uint8)

    window_vis_x = int(
        padding_vis + (window["center"] / window["img_width"]) * banner_vis_width
    )
    cv2.line(
        canvas,
        (window_vis_x, y_offset),
        (window_vis_x, y_offset + banner_h),
        (0, 200, 0, 255),
        2,
    )

    text_vis_x = int(text_bounds["center_frac"] * vis_width)
    cv2.line(
        canvas,
        (text_vis_x, y_offset),
        (text_vis_x, y_offset + banner_h),
        (0, 0, 255, 255),
        2,
    )

    label_y = y_offset + banner_h + 25
    cv2.putText(
        canvas,
        "Green = banner window center",
        (10, label_y),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.5,
        (0, 150, 0, 255),
        1,
    )
    cv2.putText(
        canvas,
        "Red = text center",
        (10, label_y + 20),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.5,
        (0, 0, 200, 255),
        1,
    )
    cv2.putText(
        canvas,
        f"Offset: {screen_offset['offset_px']:+.1f}px on {int(device_width)}px screen",
        (10, label_y + 40),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.5,
        (0, 0, 0, 255),
        1,
    )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    cv2.imwrite(str(output_path), canvas)


def load_mapping() -> dict[int, list[int]]:
    """Load the surah header mapping from JSON."""
    with open(MAPPING_PATH) as f:
        raw = json.load(f)
    return {int(k): v for k, v in raw.items()}


def analyze_page(
    page: int,
    header_indices: list[int],
    window: dict,
    device_width: float,
    threshold: float,
    visual: bool,
    output_dir: Path,
) -> list[dict]:
    """Analyze all header lines on a page."""
    results = []
    for line_idx in header_indices:
        line_file = line_idx + 1
        line_path = QURAN_IMAGES_DIR / str(page) / f"{line_file}.png"

        if not line_path.exists():
            results.append({"page": page, "line": line_idx, "error": "file not found"})
            continue

        text_bounds = detect_text_bounds(line_path)
        if text_bounds is None:
            results.append({"page": page, "line": line_idx, "error": "no text detected"})
            continue

        offset = compute_screen_offset(text_bounds["center_x"], window, device_width)
        flagged = abs(offset["offset_px"]) > threshold

        result = {
            "page": page,
            "line": line_idx,
            "text_center_frac": round(text_bounds["center_frac"], 4),
            "text_span": round(text_bounds["span"], 4),
            **offset,
            "flagged": flagged,
        }
        results.append(result)

        if visual:
            out_path = output_dir / f"page{page}_line{line_idx}.png"
            generate_visual_overlay(
                BANNER_PATH,
                line_path,
                window,
                text_bounds,
                offset,
                out_path,
                device_width,
            )

    return results


def print_report(all_results: list[dict], window: dict, device_width: float):
    """Print a summary report of centering analysis."""
    print("=" * 80)
    print("SURAH HEADER BANNER CENTERING REPORT")
    print("=" * 80)
    print(
        f"Banner window: cols {window['left']}–{window['right']} "
        f"(center: {window['center']:.1f}, width: {window['width']}px)"
    )
    print(f"Banner window center fraction: {window['center_frac']:.4f}")
    print(f"Device width: {device_width}px")
    print(f"Banner H padding: {BANNER_H_PADDING}px")
    print()

    valid = [r for r in all_results if "error" not in r]
    errors = [r for r in all_results if "error" in r]
    flagged = [r for r in valid if r["flagged"]]

    print(
        f"{'Page':>5} {'Line':>5} {'TextCenter':>11} {'WinCenter':>10} "
        f"{'Offset':>8} {'Status':>8}"
    )
    print("-" * 55)

    for r in valid:
        status = "!! FLAG" if r["flagged"] else "OK"
        print(
            f"{r['page']:>5} {r['line']:>5} {r['text_screen_x']:>10.2f}px "
            f"{r['window_screen_x']:>9.2f}px {r['offset_px']:>+7.2f}px {status:>8}"
        )

    if errors:
        print()
        print("ERRORS:")
        for r in errors:
            print(f"  Page {r['page']}, line {r['line']}: {r['error']}")

    print()
    print("-" * 55)
    print(f"Total headers analyzed: {len(valid)}")
    print(f"Flagged (offset > threshold): {len(flagged)}")

    if valid:
        offsets = [r["offset_px"] for r in valid]
        abs_offsets = [abs(o) for o in offsets]
        print(f"Mean offset: {np.mean(offsets):+.2f}px")
        print(f"Mean |offset|: {np.mean(abs_offsets):.2f}px")
        print(
            f"Max |offset|: {np.max(abs_offsets):.2f}px "
            f"(page {valid[np.argmax(abs_offsets)]['page']})"
        )
        print(f"Min |offset|: {np.min(abs_offsets):.2f}px")


def main():
    parser = argparse.ArgumentParser(
        description="Validate surah header banner centering"
    )
    parser.add_argument(
        "--page",
        default="601",
        help="Page number to analyze, or 'all' for every page (default: 601)",
    )
    parser.add_argument(
        "--device-width",
        type=float,
        default=393,
        help="Simulated device width in logical pixels (default: 393)",
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=2.0,
        help="Flag offset threshold in screen pixels (default: 2.0)",
    )
    parser.add_argument(
        "--visual",
        action="store_true",
        help="Generate overlay debug images",
    )
    parser.add_argument(
        "--output-dir",
        default="/tmp/header_centering",
        help="Output directory for visual overlays",
    )
    args = parser.parse_args()

    output_dir = Path(args.output_dir)

    print("Detecting banner window region...")
    window = detect_banner_window(BANNER_PATH)
    print(
        f"  Window: cols {window['left']}–{window['right']}, "
        f"center={window['center']:.1f} ({window['center_frac']:.4f})"
    )

    mapping = load_mapping()

    if args.page.lower() == "all":
        pages_to_analyze = sorted(mapping.keys())
    else:
        page_num = int(args.page)
        if page_num not in mapping:
            print(f"Page {page_num} has no surah headers in the mapping.")
            return
        pages_to_analyze = [page_num]

    all_results = []
    for page in pages_to_analyze:
        results = analyze_page(
            page,
            mapping[page],
            window,
            args.device_width,
            args.threshold,
            args.visual,
            output_dir,
        )
        all_results.extend(results)

    print()
    print_report(all_results, window, args.device_width)

    if args.visual:
        visual_count = sum(1 for r in all_results if "error" not in r)
        print(f"\nVisual overlays saved to: {output_dir}/ ({visual_count} images)")


if __name__ == "__main__":
    main()
