#!/usr/bin/env python3
"""
Validate Surah header banner centering from rendered screenshots.

This script compares the rendered Surah header banners in a candidate screenshot
against an Ayah App reference screenshot. It measures the black surah-name ink
inside each banner, then reports whether the candidate banner text is centered
like the reference.

It is intentionally screenshot-based, so it catches visual shifts introduced by
widget layout or positioning, including vertical drift that source-asset checks
can miss.

Examples:
    python3 validate_header_centering_screenshot.py \
      --reference ~/Desktop/ayah_app_page601.png \
      --candidate "/path/to/current_or_composite_screenshot.png"

    python3 validate_header_centering_screenshot.py \
      --reference ~/Desktop/ayah_app_page601.png \
      --candidate "/path/to/composite.png" \
      --candidate-page-index 1 \
      --visual-output /tmp/header_centering_right.png
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import cv2
import numpy as np


LIGHT_PAGE_THRESHOLD = 220
GOLD_RED_MIN = 120
GOLD_GREEN_MIN = 90
GOLD_BLUE_MAX = 170
GOLD_RED_BLUE_DELTA = 10
TEXT_BACKGROUND_PERCENTILE = 95
TEXT_BBOX_DARKNESS_PERCENTILE = 80
TEXT_MIN_DARKNESS = 8.0


@dataclass(frozen=True)
class Rect:
    x: int
    y: int
    width: int
    height: int

    @property
    def x2(self) -> int:
        return self.x + self.width

    @property
    def y2(self) -> int:
        return self.y + self.height

    @property
    def center_x(self) -> float:
        return self.x + self.width / 2.0

    @property
    def center_y(self) -> float:
        return self.y + self.height / 2.0

    def crop(self, image: np.ndarray) -> np.ndarray:
        return image[self.y : self.y2, self.x : self.x2]


@dataclass(frozen=True)
class BannerMeasurement:
    banner_rect: Rect
    text_rect: Rect
    text_center_x_norm: float
    text_center_y_norm: float

    @property
    def text_center_x_px(self) -> float:
        return self.text_rect.center_x

    @property
    def text_center_y_px(self) -> float:
        return self.text_rect.center_y


@dataclass(frozen=True)
class BannerComparison:
    index: int
    reference: BannerMeasurement
    candidate: BannerMeasurement
    delta_x_px: float
    delta_y_px: float
    pass_x: bool
    pass_y: bool

    @property
    def passed(self) -> bool:
        return self.pass_x and self.pass_y


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate screenshot-level centering of Surah header banners."
    )
    parser.add_argument(
        "--reference",
        required=True,
        help="Ayah App reference screenshot path.",
    )
    parser.add_argument(
        "--candidate",
        required=True,
        help="Candidate screenshot path. If it contains multiple pages, use --candidate-page-index.",
    )
    parser.add_argument(
        "--reference-page-index",
        type=int,
        default=0,
        help="0-based page index inside the reference screenshot after left-to-right page detection.",
    )
    parser.add_argument(
        "--candidate-page-index",
        type=int,
        default=0,
        help="0-based page index inside the candidate screenshot after left-to-right page detection.",
    )
    parser.add_argument(
        "--x-tolerance-px",
        type=float,
        default=2.0,
        help="Maximum allowed horizontal drift in candidate pixels.",
    )
    parser.add_argument(
        "--y-tolerance-px",
        type=float,
        default=1.5,
        help="Maximum allowed vertical drift in candidate pixels.",
    )
    parser.add_argument(
        "--visual-output",
        help="Optional output path for a candidate-page debug overlay.",
    )
    return parser.parse_args()


def load_rgb(path: Path) -> np.ndarray:
    image = cv2.imread(str(path), cv2.IMREAD_COLOR)
    if image is None:
        raise FileNotFoundError(f"Could not load image: {path}")
    return cv2.cvtColor(image, cv2.COLOR_BGR2RGB)


def detect_pages(image: np.ndarray) -> list[Rect]:
    gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
    mask = (gray > LIGHT_PAGE_THRESHOLD).astype(np.uint8) * 255

    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)

    image_area = image.shape[0] * image.shape[1]
    page_rects: list[Rect] = []

    num_labels, _, stats, _ = cv2.connectedComponentsWithStats(mask, 8)
    for label in range(1, num_labels):
        x, y, width, height, area = map(int, stats[label])
        if area < image_area * 0.1:
            continue
        page_rects.append(Rect(x=x, y=y, width=width, height=height))

    if not page_rects:
        return [Rect(x=0, y=0, width=image.shape[1], height=image.shape[0])]

    return sorted(page_rects, key=lambda rect: rect.x)


def select_page(image: np.ndarray, page_index: int) -> tuple[np.ndarray, Rect]:
    pages = detect_pages(image)
    if page_index < 0 or page_index >= len(pages):
        raise ValueError(
            f"Page index {page_index} is out of range. Detected {len(pages)} page(s)."
        )
    rect = pages[page_index]
    return rect.crop(image), rect


def gold_mask(page_image: np.ndarray) -> np.ndarray:
    red = page_image[:, :, 0]
    green = page_image[:, :, 1]
    blue = page_image[:, :, 2]
    mask = (
        (red > GOLD_RED_MIN)
        & (green > GOLD_GREEN_MIN)
        & (blue < GOLD_BLUE_MAX)
        & (red > blue + GOLD_RED_BLUE_DELTA)
    )
    return mask.astype(np.uint8) * 255


def detect_banner_rects(page_image: np.ndarray) -> list[Rect]:
    mask = gold_mask(page_image)

    kernel_width = max(9, int(round(page_image.shape[1] * 0.012)))
    kernel_height = max(3, int(round(page_image.shape[1] * 0.0035)))
    kernel = cv2.getStructuringElement(
        cv2.MORPH_RECT,
        (kernel_width, kernel_height),
    )
    closed = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)

    page_width = page_image.shape[1]
    banner_rects: list[Rect] = []

    num_labels, _, stats, _ = cv2.connectedComponentsWithStats(closed, 8)
    for label in range(1, num_labels):
        x, y, width, height, area = map(int, stats[label])
        density = area / float(width * height)
        if width < page_width * 0.8:
            continue
        if height < 20 or height > max(200, int(page_image.shape[0] * 0.15)):
            continue
        if density < 0.35:
            continue
        banner_rects.append(Rect(x=x, y=y, width=width, height=height))

    banner_rects.sort(key=lambda rect: rect.y)
    return banner_rects


def detect_text_rect(banner_image: np.ndarray) -> Rect:
    gray = cv2.cvtColor(banner_image, cv2.COLOR_RGB2GRAY).astype(np.float32)
    left = int(round(banner_image.shape[1] * 0.22))
    right = int(round(banner_image.shape[1] * 0.78))
    top = int(round(banner_image.shape[0] * 0.08))
    bottom = int(round(banner_image.shape[0] * 0.92))

    roi = gray[top:bottom, left:right]
    background = float(np.percentile(roi, TEXT_BACKGROUND_PERCENTILE))
    darkness = np.clip(background - roi, a_min=0.0, a_max=None)
    positive = darkness[darkness > 0]
    if len(positive) == 0:
        raise ValueError("Could not detect surah-name ink inside banner.")

    mask_threshold = max(
        TEXT_MIN_DARKNESS,
        float(np.percentile(positive, TEXT_BBOX_DARKNESS_PERCENTILE)),
    )
    text_mask = (darkness >= mask_threshold).astype(np.uint8) * 255
    text_mask = cv2.morphologyEx(
        text_mask,
        cv2.MORPH_OPEN,
        np.ones((2, 2), dtype=np.uint8),
    )

    ys, xs = np.where(text_mask > 0)
    if len(xs) == 0:
        raise ValueError("Could not build a text bounding box inside banner.")

    x0 = int(xs.min()) + left
    y0 = int(ys.min()) + top
    x1 = int(xs.max()) + left
    y1 = int(ys.max()) + top
    return Rect(x=x0, y=y0, width=x1 - x0 + 1, height=y1 - y0 + 1)


def detect_text_center(banner_image: np.ndarray) -> tuple[float, float]:
    gray = cv2.cvtColor(banner_image, cv2.COLOR_RGB2GRAY).astype(np.float32)
    left = int(round(banner_image.shape[1] * 0.22))
    right = int(round(banner_image.shape[1] * 0.78))
    top = int(round(banner_image.shape[0] * 0.08))
    bottom = int(round(banner_image.shape[0] * 0.92))

    roi = gray[top:bottom, left:right]
    background = float(np.percentile(roi, TEXT_BACKGROUND_PERCENTILE))
    darkness = np.clip(background - roi, a_min=0.0, a_max=None)
    total_darkness = float(darkness.sum())
    if total_darkness <= 0:
        raise ValueError("Could not measure surah-name center inside banner.")

    ys, xs = np.indices(darkness.shape, dtype=np.float32)
    center_x = float((xs * darkness).sum() / total_darkness) + left
    center_y = float((ys * darkness).sum() / total_darkness) + top
    return center_x / banner_image.shape[1], center_y / banner_image.shape[0]


def measure_banners(page_image: np.ndarray) -> list[BannerMeasurement]:
    banner_rects = detect_banner_rects(page_image)
    if not banner_rects:
        raise ValueError("No banner rectangles were detected on the selected page.")

    measurements: list[BannerMeasurement] = []
    for banner_rect in banner_rects:
        banner_image = banner_rect.crop(page_image)
        text_rect = detect_text_rect(banner_image)
        text_center_x_norm, text_center_y_norm = detect_text_center(banner_image)
        measurements.append(
            BannerMeasurement(
                banner_rect=banner_rect,
                text_rect=text_rect,
                text_center_x_norm=text_center_x_norm,
                text_center_y_norm=text_center_y_norm,
            )
        )
    return measurements


def compare_measurements(
    reference: Iterable[BannerMeasurement],
    candidate: Iterable[BannerMeasurement],
    x_tolerance_px: float,
    y_tolerance_px: float,
) -> list[BannerComparison]:
    reference_list = list(reference)
    candidate_list = list(candidate)

    if len(reference_list) != len(candidate_list):
        raise ValueError(
            "Reference and candidate pages have different banner counts: "
            f"{len(reference_list)} vs {len(candidate_list)}."
        )

    comparisons: list[BannerComparison] = []
    for index, (ref_banner, cand_banner) in enumerate(
        zip(reference_list, candidate_list, strict=True),
        start=1,
    ):
        delta_x_px = (
            cand_banner.text_center_x_norm - ref_banner.text_center_x_norm
        ) * cand_banner.banner_rect.width
        delta_y_px = (
            cand_banner.text_center_y_norm - ref_banner.text_center_y_norm
        ) * cand_banner.banner_rect.height

        comparisons.append(
            BannerComparison(
                index=index,
                reference=ref_banner,
                candidate=cand_banner,
                delta_x_px=delta_x_px,
                delta_y_px=delta_y_px,
                pass_x=abs(delta_x_px) <= x_tolerance_px,
                pass_y=abs(delta_y_px) <= y_tolerance_px,
            )
        )

    return comparisons


def draw_visual_overlay(
    candidate_page: np.ndarray,
    comparisons: Iterable[BannerComparison],
    output_path: Path,
) -> None:
    overlay = candidate_page.copy()

    for comparison in comparisons:
        banner_rect = comparison.candidate.banner_rect
        cand_text = comparison.candidate.text_rect
        ref_text = comparison.reference.text_rect

        cv2.rectangle(
            overlay,
            (banner_rect.x, banner_rect.y),
            (banner_rect.x2, banner_rect.y2),
            (52, 91, 255),
            1,
        )

        candidate_box = Rect(
            x=banner_rect.x + cand_text.x,
            y=banner_rect.y + cand_text.y,
            width=cand_text.width,
            height=cand_text.height,
        )
        cv2.rectangle(
            overlay,
            (candidate_box.x, candidate_box.y),
            (candidate_box.x2, candidate_box.y2),
            (255, 59, 48),
            2,
        )

        expected_box = Rect(
            x=banner_rect.x
            + int(round(comparison.reference.text_center_x_norm * banner_rect.width))
            - max(
                1,
                int(
                    round(
                        ref_text.width
                        * banner_rect.width
                        / comparison.reference.banner_rect.width
                        / 2.0
                    )
                ),
            ),
            y=banner_rect.y
            + int(round(comparison.reference.text_center_y_norm * banner_rect.height))
            - max(
                1,
                int(
                    round(
                        ref_text.height
                        * banner_rect.height
                        / comparison.reference.banner_rect.height
                        / 2.0
                    )
                ),
            ),
            width=max(
                1,
                int(
                    round(
                        ref_text.width
                        * banner_rect.width
                        / comparison.reference.banner_rect.width
                    )
                ),
            ),
            height=max(
                1,
                int(
                    round(
                        ref_text.height
                        * banner_rect.height
                        / comparison.reference.banner_rect.height
                    )
                ),
            ),
        )
        cv2.rectangle(
            overlay,
            (expected_box.x, expected_box.y),
            (expected_box.x2, expected_box.y2),
            (52, 199, 89),
            2,
        )

        candidate_center = (
            int(round(candidate_box.center_x)),
            int(round(candidate_box.center_y)),
        )
        expected_center = (
            int(
                round(
                    banner_rect.x
                    + comparison.reference.text_center_x_norm * banner_rect.width
                )
            ),
            int(
                round(
                    banner_rect.y
                    + comparison.reference.text_center_y_norm * banner_rect.height
                )
            ),
        )
        cv2.circle(overlay, candidate_center, 3, (255, 59, 48), -1)
        cv2.circle(overlay, expected_center, 3, (52, 199, 89), -1)

        label = (
            f"#{comparison.index} dx={comparison.delta_x_px:+.2f}px "
            f"dy={comparison.delta_y_px:+.2f}px"
        )
        cv2.putText(
            overlay,
            label,
            (banner_rect.x, max(18, banner_rect.y - 6)),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.45,
            (0, 0, 0),
            2,
            cv2.LINE_AA,
        )
        cv2.putText(
            overlay,
            label,
            (banner_rect.x, max(18, banner_rect.y - 6)),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.45,
            (255, 255, 255),
            1,
            cv2.LINE_AA,
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    cv2.imwrite(str(output_path), cv2.cvtColor(overlay, cv2.COLOR_RGB2BGR))


def print_report(
    comparisons: Iterable[BannerComparison],
    reference_page_rect: Rect,
    candidate_page_rect: Rect,
    reference_path: Path,
    candidate_path: Path,
) -> bool:
    comparison_list = list(comparisons)
    overall_pass = all(item.passed for item in comparison_list)

    print("=" * 84)
    print("SURAH HEADER BANNER CENTERING REPORT")
    print("=" * 84)
    print(f"Reference: {reference_path}")
    print(
        "  Page rect:"
        f" x={reference_page_rect.x}, y={reference_page_rect.y},"
        f" w={reference_page_rect.width}, h={reference_page_rect.height}"
    )
    print(f"Candidate: {candidate_path}")
    print(
        "  Page rect:"
        f" x={candidate_page_rect.x}, y={candidate_page_rect.y},"
        f" w={candidate_page_rect.width}, h={candidate_page_rect.height}"
    )
    print()
    print(
        f"{'Banner':>6} {'RefX':>8} {'RefY':>8} {'CandX':>8} {'CandY':>8}"
        f" {'dX(px)':>9} {'dY(px)':>9} {'Status':>9}"
    )
    print("-" * 84)

    for item in comparison_list:
        status = "PASS" if item.passed else "FAIL"
        print(
            f"{item.index:>6}"
            f" {item.reference.text_center_x_norm:>8.4f}"
            f" {item.reference.text_center_y_norm:>8.4f}"
            f" {item.candidate.text_center_x_norm:>8.4f}"
            f" {item.candidate.text_center_y_norm:>8.4f}"
            f" {item.delta_x_px:>+9.2f}"
            f" {item.delta_y_px:>+9.2f}"
            f" {status:>9}"
        )

    print("-" * 84)
    print(f"Overall result: {'PASS' if overall_pass else 'FAIL'}")

    failures = [item for item in comparison_list if not item.passed]
    if failures:
        print("Failed banners:")
        for item in failures:
            reasons: list[str] = []
            if not item.pass_x:
                reasons.append(f"x drift {item.delta_x_px:+.2f}px")
            if not item.pass_y:
                reasons.append(f"y drift {item.delta_y_px:+.2f}px")
            print(f"  Banner #{item.index}: {', '.join(reasons)}")

    return overall_pass


def main() -> int:
    args = parse_args()

    reference_path = Path(args.reference).expanduser().resolve()
    candidate_path = Path(args.candidate).expanduser().resolve()

    reference_image = load_rgb(reference_path)
    candidate_image = load_rgb(candidate_path)

    reference_page, reference_page_rect = select_page(
        reference_image,
        args.reference_page_index,
    )
    candidate_page, candidate_page_rect = select_page(
        candidate_image,
        args.candidate_page_index,
    )

    reference_measurements = measure_banners(reference_page)
    candidate_measurements = measure_banners(candidate_page)
    comparisons = compare_measurements(
        reference=reference_measurements,
        candidate=candidate_measurements,
        x_tolerance_px=args.x_tolerance_px,
        y_tolerance_px=args.y_tolerance_px,
    )

    overall_pass = print_report(
        comparisons=comparisons,
        reference_page_rect=reference_page_rect,
        candidate_page_rect=candidate_page_rect,
        reference_path=reference_path,
        candidate_path=candidate_path,
    )

    if args.visual_output:
        output_path = Path(args.visual_output).expanduser().resolve()
        draw_visual_overlay(
            candidate_page=candidate_page,
            comparisons=comparisons,
            output_path=output_path,
        )
        print(f"Visual overlay saved to: {output_path}")

    return 0 if overall_pass else 1


if __name__ == "__main__":
    raise SystemExit(main())
