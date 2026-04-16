#!/usr/bin/env python3
"""
Validate that surah name text is properly centered within the header banner.

Faithfully simulates the Flutter _SurahHeaderBanner widget logic:
  - Regression-based banner width & horizontal padding
  - Per-header ink-center-Y fractions with Transform.translate vertical offset
  - lineHeight = pageWidth * 174 / 1080

Usage:
    python3 validate_header_centering.py                          # Analyze page 601
    python3 validate_header_centering.py --page all               # Analyze all pages
    python3 validate_header_centering.py --page 601 --visual      # Generate overlay images
"""

import argparse
import json
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
LINE_IMG_WIDTH = 1440
LINE_IMG_HEIGHT = 232

# --- Regression constants (must match quran_image_page.dart) ---
BANNER_HEIGHT_TO_WIDTH_RATIO = 0.11228293967474158
PORTRAIT_WIDTH_RATIO_BASE = 0.97354259
PORTRAIT_WIDTH_RATIO_ASPECT_SLOPE = -0.015786
PORTRAIT_WIDTH_RATIO_VIEWPORT_SLOPE = -0.0000049331266667
TARGET_INK_CENTER_Y_FRACTION = 0.509

# --- Per-header ink Y fractions (must match _headerInkCenterYFractions in Dart) ---
HEADER_INK_CENTER_Y_FRACTIONS: dict[int, dict[int, float]] = {
    1: {3: 0.5000, 11: 0.5108},
    2: {3: 0.5022, 11: 0.5108},
    50: {0: 0.4526},
    77: {0: 0.4806},
    106: {5: 0.5302},
    128: {0: 0.4504},
    151: {0: 0.4461},
    177: {0: 0.4612},
    187: {0: 0.4720},
    208: {0: 0.4569},
    221: {6: 0.4698},
    235: {8: 0.5560},
    249: {0: 0.4720},
    255: {2: 0.4914},
    262: {0: 0.4634},
    267: {6: 0.5043},
    282: {0: 0.4698},
    293: {9: 0.6099},
    305: {0: 0.4569},
    312: {4: 0.4957},
    322: {0: 0.4591},
    332: {0: 0.4655},
    342: {0: 0.4655},
    350: {0: 0.4634},
    359: {10: 0.5711},
    367: {0: 0.4634},
    377: {0: 0.4655},
    385: {7: 0.5539},
    396: {7: 0.5237},
    404: {9: 0.6250},
    411: {0: 0.4504},
    415: {0: 0.4591},
    418: {0: 0.4612},
    428: {0: 0.4741},
    434: {7: 0.5841},
    440: {3: 0.4741},
    446: {0: 0.4677},
    453: {0: 0.4634},
    458: {3: 0.5280},
    467: {2: 0.5453},
    477: {0: 0.4634},
    483: {0: 0.4612},
    489: {4: 0.5948},
    496: {0: 0.4677},
    499: {0: 0.4612},
    502: {6: 0.5323},
    507: {0: 0.4741},
    511: {0: 0.4763},
    515: {6: 0.5841},
    518: {0: 0.4655},
    520: {11: 0.5927},
    523: {7: 0.5129},
    526: {0: 0.4677},
    528: {9: 0.5043},
    531: {4: 0.5690},
    534: {6: 0.5151},
    537: {10: 0.5991},
    542: {0: 0.4612},
    545: {6: 0.5172},
    549: {0: 0.4655},
    551: {6: 0.5474},
    553: {0: 0.4655},
    554: {6: 0.5517},
    556: {0: 0.4720},
    558: {0: 0.4634},
    560: {0: 0.4698},
    562: {0: 0.4547},
    564: {5: 0.5948},
    566: {9: 0.5517},
    568: {8: 0.5991},
    570: {4: 0.5237},
    572: {0: 0.4698},
    574: {0: 0.4634},
    575: {7: 0.5302},
    577: {5: 0.4634},
    578: {9: 0.5302},
    580: {6: 0.5237},
    582: {0: 0.4763},
    583: {7: 0.5582},
    585: {0: 0.4612},
    586: {1: 0.5259},
    587: {0: 0.4698, 11: 0.5690},
    589: {2: 0.5172},
    590: {1: 0.5366},
    591: {0: 0.4655, 9: 0.5474},
    592: {4: 0.4978},
    593: {2: 0.4978},
    594: {5: 0.5560},
    595: {1: 0.5216, 10: 0.5690},
    596: {5: 0.5000, 12: 0.5151},
    597: {2: 0.5496, 8: 0.5366},
    598: {3: 0.5302, 8: 0.6142},
    599: {5: 0.5409, 11: 0.5733},
    600: {3: 0.5043, 10: 0.4935},
    601: {0: 0.4634, 4: 0.5280, 10: 0.6013},
    602: {0: 0.4634, 5: 0.5884, 11: 0.5690},
    603: {0: 0.4461, 5: 0.5431, 10: 0.5690},
    604: {0: 0.4483, 4: 0.5237, 9: 0.5862},
}


def detect_banner_window(banner_path: Path) -> dict:
    """Detect the ornamental window region in the header banner."""
    img = cv2.imread(str(banner_path), cv2.IMREAD_UNCHANGED)
    if img is None:
        raise FileNotFoundError(f"Cannot load banner: {banner_path}")

    gray = cv2.cvtColor(img[:, :, :3], cv2.COLOR_BGR2GRAY)
    col_std = gray.astype(np.float64).std(axis=0)

    kernel = np.ones(20) / 20
    smoothed = np.convolve(col_std, kernel, mode="same")

    center = img.shape[1] // 2
    threshold = 30.0

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

    if span >= HEADER_SPAN_MAX:
        return None

    row_max = alpha.max(axis=1)
    trows = np.where(row_max > ALPHA_THRESHOLD)[0]

    text_center_x = (text_left + text_right) / 2.0
    text_center_y = (int(trows[0]) + int(trows[-1])) / 2.0

    return {
        "left": text_left,
        "right": text_right,
        "top": int(trows[0]),
        "bottom": int(trows[-1]),
        "center_x": text_center_x,
        "center_y": text_center_y,
        "center_x_frac": text_center_x / img.shape[1],
        "center_y_frac": text_center_y / img.shape[0],
        "span": span,
        "img_width": img.shape[1],
        "img_height": img.shape[0],
    }


def compute_banner_layout(device_width: float, device_height: float) -> dict:
    """Compute banner dimensions using the Ayah app regression model."""
    short_side = min(device_width, device_height)
    long_side = max(device_width, device_height)
    aspect_ratio = short_side / long_side if long_side > 0 else 0

    width_ratio = (
        PORTRAIT_WIDTH_RATIO_BASE
        + PORTRAIT_WIDTH_RATIO_ASPECT_SLOPE * aspect_ratio
        + PORTRAIT_WIDTH_RATIO_VIEWPORT_SLOPE * device_width
    )
    width_ratio = max(0.0, min(1.0, width_ratio))

    banner_width = round(device_width * width_ratio)
    banner_height = round(banner_width * BANNER_HEIGHT_TO_WIDTH_RATIO)
    h_padding = (device_width - banner_width) / 2
    line_height = device_width * 174 / 1080

    return {
        "banner_width": banner_width,
        "banner_height": banner_height,
        "h_padding": h_padding,
        "line_height": line_height,
        "width_ratio": width_ratio,
    }


def compute_vertical_offset(
    layout: dict,
    page: int,
    line_idx: int,
) -> dict:
    """Compute the Transform.translate vertical offset matching the Dart widget."""
    line_height = layout["line_height"]
    banner_height = layout["banner_height"]

    ink_y_frac = HEADER_INK_CENTER_Y_FRACTIONS.get(page, {}).get(line_idx, 0.5)

    # Match Dart: centeredTop = (lineHeight - bannerHeight) / 2
    centered_top = (line_height - banner_height) / 2

    # Match Dart: desiredTop = (lineHeight * inkFrac) - (bannerHeight * targetFrac)
    desired_top = (line_height * ink_y_frac) - (banner_height * TARGET_INK_CENTER_Y_FRACTION)

    # Match Dart: verticalOffset = desiredTop - centeredTop
    vertical_offset = desired_top - centered_top

    # The banner's actual top within the line slot (relative to slot top)
    actual_banner_top = centered_top + vertical_offset  # == desiredTop

    # Banner center in the line slot
    banner_center_y = actual_banner_top + banner_height / 2

    return {
        "ink_y_frac": ink_y_frac,
        "centered_top": round(centered_top, 2),
        "desired_top": round(desired_top, 2),
        "vertical_offset": round(vertical_offset, 2),
        "banner_center_y": round(banner_center_y, 2),
        "banner_center_y_frac": round(banner_center_y / line_height, 4),
    }


def compute_screen_offset(
    text_bounds: dict,
    window: dict,
    layout: dict,
) -> dict:
    """Compute screen-space horizontal offset between text center and banner window center."""
    device_width = layout["banner_width"] + 2 * layout["h_padding"]  # == pageWidth

    # Line image stretches full width
    text_screen_x = (text_bounds["center_x"] / LINE_IMG_WIDTH) * device_width

    # Banner has horizontal padding, window center within banner
    window_screen_x = (
        layout["h_padding"]
        + (window["center"] / window["img_width"]) * layout["banner_width"]
    )

    offset_px = text_screen_x - window_screen_x

    return {
        "text_screen_x": round(text_screen_x, 2),
        "window_screen_x": round(window_screen_x, 2),
        "h_offset_px": round(offset_px, 2),
    }


def compute_vertical_screen_offset(
    text_bounds: dict,
    layout: dict,
    v_offset: dict,
) -> dict:
    """Compute screen-space vertical offset between text center and banner center."""
    line_height = layout["line_height"]

    # Text center Y in the line slot (line image fills lineHeight via BoxFit.fill)
    text_screen_y = (text_bounds["center_y_frac"]) * line_height

    # Banner center Y in the line slot (after Transform.translate)
    banner_center_y = v_offset["banner_center_y"]

    v_offset_px = text_screen_y - banner_center_y

    return {
        "text_screen_y": round(text_screen_y, 2),
        "banner_center_y": round(banner_center_y, 2),
        "v_offset_px": round(v_offset_px, 2),
    }


def load_mapping() -> dict[int, list[int]]:
    with open(MAPPING_PATH) as f:
        raw = json.load(f)
    return {int(k): v for k, v in raw.items()}


def analyze_page(
    page: int,
    header_indices: list[int],
    window: dict,
    layout: dict,
    h_threshold: float,
    v_threshold: float,
    visual: bool,
    output_dir: Path,
) -> list[dict]:
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

        h_off = compute_screen_offset(text_bounds, window, layout)
        v_data = compute_vertical_offset(layout, page, line_idx)
        v_off = compute_vertical_screen_offset(text_bounds, layout, v_data)

        h_flagged = abs(h_off["h_offset_px"]) > h_threshold
        v_flagged = abs(v_off["v_offset_px"]) > v_threshold

        result = {
            "page": page,
            "line": line_idx,
            "ink_y_frac": v_data["ink_y_frac"],
            "text_cy_frac": text_bounds["center_y_frac"],
            "v_translate": v_data["vertical_offset"],
            **h_off,
            **v_off,
            "h_flagged": h_flagged,
            "v_flagged": v_flagged,
        }
        results.append(result)

        if visual:
            out_path = output_dir / f"page{page}_line{line_idx}.png"
            generate_visual_overlay(
                BANNER_PATH, line_path, window, text_bounds,
                layout, v_data, h_off, v_off, out_path,
            )

    return results


def generate_visual_overlay(
    banner_path: Path,
    line_path: Path,
    window: dict,
    text_bounds: dict,
    layout: dict,
    v_data: dict,
    h_off: dict,
    v_off: dict,
    output_path: Path,
):
    """Generate a debug overlay showing banner + text alignment."""
    banner = cv2.imread(str(banner_path), cv2.IMREAD_UNCHANGED)
    line_img = cv2.imread(str(line_path), cv2.IMREAD_UNCHANGED)

    vis_width = 800
    line_height = layout["line_height"]
    banner_height = layout["banner_height"]
    device_width = layout["banner_width"] + 2 * layout["h_padding"]

    # Scale to vis_width for the full line slot height
    vis_line_h = int(line_height / device_width * vis_width)
    vis_banner_h = int(banner_height / device_width * vis_width)

    canvas_h = vis_line_h + 80
    canvas = np.ones((canvas_h, vis_width, 4), dtype=np.uint8) * 255
    canvas[:, :, 3] = 255

    # Banner position (after Transform.translate)
    padding_vis = int(layout["h_padding"] / device_width * vis_width)
    banner_vis_w = vis_width - 2 * padding_vis
    banner_top_vis = int(v_data["desired_top"] / device_width * vis_width)

    banner_resized = cv2.resize(banner, (banner_vis_w, vis_banner_h))
    y0 = max(0, banner_top_vis)
    y1 = min(canvas_h, banner_top_vis + vis_banner_h)
    by0 = y0 - banner_top_vis
    by1 = by0 + (y1 - y0)
    if y1 > y0:
        canvas[y0:y1, padding_vis:padding_vis + banner_vis_w, :] = banner_resized[by0:by1]

    # Line image overlay (full width, full line slot height)
    line_resized = cv2.resize(line_img, (vis_width, vis_line_h))
    for r in range(vis_line_h):
        for c in range(vis_width):
            a = line_resized[r, c, 3] / 255.0
            if a > 0.05:
                canvas[r, c, :3] = (
                    (1 - a) * canvas[r, c, :3] + a * line_resized[r, c, :3]
                ).astype(np.uint8)

    # Horizontal center lines
    window_vis_x = int(padding_vis + (window["center"] / window["img_width"]) * banner_vis_w)
    text_vis_x = int(text_bounds["center_x_frac"] * vis_width)
    cv2.line(canvas, (window_vis_x, 0), (window_vis_x, vis_line_h), (0, 200, 0, 255), 1)
    cv2.line(canvas, (text_vis_x, 0), (text_vis_x, vis_line_h), (0, 0, 255, 255), 1)

    # Vertical center lines
    banner_cy_vis = int(v_data["banner_center_y"] / device_width * vis_width)
    text_cy_vis = int(text_bounds["center_y_frac"] * vis_line_h)
    cv2.line(canvas, (padding_vis, banner_cy_vis), (padding_vis + banner_vis_w, banner_cy_vis), (0, 200, 0, 255), 1)
    cv2.line(canvas, (0, text_cy_vis), (vis_width, text_cy_vis), (0, 0, 255, 255), 1)

    # Labels
    ly = vis_line_h + 15
    cv2.putText(canvas, f"H offset: {h_off['h_offset_px']:+.2f}px  V offset: {v_off['v_offset_px']:+.2f}px", (10, ly), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (0, 0, 0, 255), 1)
    cv2.putText(canvas, f"ink_y_frac={v_data['ink_y_frac']:.4f}  translate_y={v_data['vertical_offset']:+.2f}px", (10, ly + 18), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (0, 0, 0, 255), 1)
    cv2.putText(canvas, "Green=banner center  Red=text center", (10, ly + 36), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (80, 80, 80, 255), 1)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    cv2.imwrite(str(output_path), canvas)


def print_report(all_results: list[dict], layout: dict):
    device_width = layout["banner_width"] + 2 * layout["h_padding"]
    print("=" * 95)
    print("SURAH HEADER BANNER CENTERING REPORT")
    print("=" * 95)
    print(f"Device: {device_width:.0f}x{device_width * 852 / 393:.0f}px  "
          f"Banner: {layout['banner_width']}x{layout['banner_height']}px  "
          f"LineHeight: {layout['line_height']:.1f}px  "
          f"Padding: {layout['h_padding']:.1f}px")
    print(f"Target ink center Y fraction: {TARGET_INK_CENTER_Y_FRACTION}")
    print()

    valid = [r for r in all_results if "error" not in r]
    errors = [r for r in all_results if "error" in r]

    print(f"{'Page':>5} {'Line':>5} {'inkYfrac':>9} {'vTranslate':>11} "
          f"{'Hoffset':>9} {'Voffset':>9} {'Status':>8}")
    print("-" * 65)

    for r in valid:
        h_flag = "H!" if r["h_flagged"] else ""
        v_flag = "V!" if r["v_flagged"] else ""
        status = f"{h_flag}{v_flag}" if (h_flag or v_flag) else "OK"
        print(f"{r['page']:>5} {r['line']:>5} {r['ink_y_frac']:>9.4f} "
              f"{r['v_translate']:>+10.2f}px "
              f"{r['h_offset_px']:>+8.2f}px {r['v_offset_px']:>+8.2f}px {status:>8}")

    if errors:
        print()
        for r in errors:
            print(f"  ERROR: Page {r['page']}, line {r['line']}: {r['error']}")

    print("-" * 65)
    h_flagged = [r for r in valid if r["h_flagged"]]
    v_flagged = [r for r in valid if r["v_flagged"]]
    print(f"Total: {len(valid)}  H-flagged: {len(h_flagged)}  V-flagged: {len(v_flagged)}")

    if valid:
        h_offsets = [abs(r["h_offset_px"]) for r in valid]
        v_offsets = [abs(r["v_offset_px"]) for r in valid]
        print(f"Mean |H|: {np.mean(h_offsets):.2f}px  Max |H|: {np.max(h_offsets):.2f}px")
        print(f"Mean |V|: {np.mean(v_offsets):.2f}px  Max |V|: {np.max(v_offsets):.2f}px")

    # Cross-check: verify ink_y_frac matches actual text center
    mismatches = []
    for r in valid:
        delta = abs(r["ink_y_frac"] - r["text_cy_frac"])
        if delta > 0.01:
            mismatches.append(r)
    if mismatches:
        print()
        print(f"WARNING: {len(mismatches)} headers have ink_y_frac != actual text center_y_frac (>1%):")
        for r in mismatches:
            print(f"  Page {r['page']} line {r['line']}: "
                  f"ink_y_frac={r['ink_y_frac']:.4f} vs actual={r['text_cy_frac']:.4f} "
                  f"(delta={abs(r['ink_y_frac'] - r['text_cy_frac']):.4f})")


def main():
    parser = argparse.ArgumentParser(description="Validate surah header banner centering")
    parser.add_argument("--page", default="601",
                        help="Page number or 'all' (default: 601)")
    parser.add_argument("--device-width", type=float, default=393,
                        help="Simulated device width (default: 393)")
    parser.add_argument("--device-height", type=float, default=852,
                        help="Simulated device height (default: 852)")
    parser.add_argument("--h-threshold", type=float, default=2.0,
                        help="Horizontal offset flag threshold in px (default: 2.0)")
    parser.add_argument("--v-threshold", type=float, default=2.0,
                        help="Vertical offset flag threshold in px (default: 2.0)")
    parser.add_argument("--visual", action="store_true",
                        help="Generate overlay debug images")
    parser.add_argument("--output-dir", default="/tmp/header_centering",
                        help="Output directory for overlays")
    args = parser.parse_args()

    output_dir = Path(args.output_dir)

    print("Detecting banner window region...")
    window = detect_banner_window(BANNER_PATH)
    print(f"  Window: cols {window['left']}–{window['right']}, "
          f"center={window['center']:.1f} ({window['center_frac']:.4f})")

    layout = compute_banner_layout(args.device_width, args.device_height)
    print(f"  Layout: banner={layout['banner_width']}x{layout['banner_height']}px, "
          f"padding={layout['h_padding']:.1f}px, lineHeight={layout['line_height']:.1f}px")

    mapping = load_mapping()

    if args.page.lower() == "all":
        pages = sorted(mapping.keys())
    else:
        page_num = int(args.page)
        if page_num not in mapping:
            print(f"Page {page_num} has no surah headers in the mapping.")
            return
        pages = [page_num]

    all_results = []
    for page in pages:
        results = analyze_page(
            page, mapping[page], window, layout,
            args.h_threshold, args.v_threshold, args.visual, output_dir,
        )
        all_results.extend(results)

    print()
    print_report(all_results, layout)

    if args.visual:
        n = sum(1 for r in all_results if "error" not in r)
        print(f"\nVisual overlays saved to: {output_dir}/ ({n} images)")


if __name__ == "__main__":
    main()
