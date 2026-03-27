#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from dataclasses import asdict, dataclass
from pathlib import Path

import numpy as np
from PIL import Image


@dataclass(frozen=True)
class Rect:
  left: int
  top: int
  right: int
  bottom: int

  @property
  def width(self) -> int:
    return self.right - self.left

  @property
  def height(self) -> int:
    return self.bottom - self.top

  def expand(self, pad: int, limit_width: int, limit_height: int) -> "Rect":
    return Rect(
      left=max(0, self.left - pad),
      top=max(0, self.top - pad),
      right=min(limit_width, self.right + pad),
      bottom=min(limit_height, self.bottom + pad),
    )


@dataclass(frozen=True)
class AlignmentResult:
  scale: float
  dx: int
  dy: int
  mask_iou: float
  signal_correlation: float


def parse_args() -> argparse.Namespace:
  parser = argparse.ArgumentParser(
    description=(
      "Align a Tilawa Quran page screenshot to an Ayah reference and emit "
      "pixel-diff metrics plus visual artifacts."
    ),
  )
  parser.add_argument("--tilawa", type=Path, help="Path to the Tilawa screenshot.")
  parser.add_argument("--ayah", type=Path, help="Path to the Ayah screenshot.")
  parser.add_argument(
    "--screenshots-dir",
    type=Path,
    default=Path("screenshots"),
    help="Folder containing screenshots. Used when --tilawa/--ayah are omitted.",
  )
  parser.add_argument(
    "--pair-key",
    default="quran_page_2",
    help=(
      "Shared suffix used to auto-resolve screenshots inside --screenshots-dir. "
      "Example: quran_page_2 resolves tilawa_quran_page_2.* and ayah_app_quran_page_2.*"
    ),
  )
  parser.add_argument(
    "--output-dir",
    type=Path,
    default=Path("/tmp/quran_page_compare"),
    help="Directory where aligned images, diff maps, and metrics will be written.",
  )
  parser.add_argument(
    "--scale-min",
    type=float,
    default=0.94,
    help="Minimum scale factor applied to the Tilawa crop during search.",
  )
  parser.add_argument(
    "--scale-max",
    type=float,
    default=1.06,
    help="Maximum scale factor applied to the Tilawa crop during search.",
  )
  parser.add_argument(
    "--scale-step",
    type=float,
    default=0.0025,
    help="Scale step used during the search.",
  )
  parser.add_argument(
    "--crop-threshold",
    type=int,
    default=18,
    help="Difference-from-background threshold used to detect content bounds.",
  )
  parser.add_argument(
    "--signal-threshold",
    type=float,
    default=0.06,
    help="Minimum normalized darkness to keep in the comparison signal.",
  )
  parser.add_argument(
    "--ink-threshold",
    type=float,
    default=0.18,
    help="Minimum normalized darkness treated as verse ink for line metrics.",
  )
  parser.add_argument(
    "--ignore-top-ratio",
    type=float,
    default=0.04,
    help="Top strip ignored while detecting the content bounds.",
  )
  parser.add_argument(
    "--ignore-bottom-ratio",
    type=float,
    default=0.02,
    help="Bottom strip ignored while detecting the content bounds.",
  )
  parser.add_argument(
    "--crop-padding",
    type=int,
    default=10,
    help="Padding added around detected content bounds.",
  )
  parser.add_argument(
    "--analysis-long-side",
    type=int,
    default=420,
    help="Longest side used for the coarse alignment search.",
  )
  return parser.parse_args()


def resolve_pair(args: argparse.Namespace) -> tuple[Path, Path]:
  if args.tilawa and args.ayah:
    return args.tilawa.resolve(), args.ayah.resolve()

  screenshots_dir = args.screenshots_dir.resolve()
  pair_key = args.pair_key
  tilawa_matches = sorted(screenshots_dir.glob(f"tilawa_{pair_key}.*"))
  ayah_matches = sorted(screenshots_dir.glob(f"ayah_app_{pair_key}.*"))

  if not tilawa_matches or not ayah_matches:
    raise FileNotFoundError(
      "Could not resolve a screenshot pair. Pass --tilawa and --ayah explicitly "
      "or ensure screenshots/ contains matching tilawa_*/ayah_app_* files."
    )

  return tilawa_matches[0], ayah_matches[0]


def load_rgb(path: Path) -> Image.Image:
  return Image.open(path).convert("RGB")


def image_to_rgb_array(image: Image.Image) -> np.ndarray:
  return np.asarray(image, dtype=np.uint8)


def image_to_gray_array(image: Image.Image) -> np.ndarray:
  rgb = image_to_rgb_array(image).astype(np.float32)
  return (
    rgb[..., 0] * 0.299 + rgb[..., 1] * 0.587 + rgb[..., 2] * 0.114
  ) / 255.0


def sample_background_rgb(rgb: np.ndarray) -> np.ndarray:
  h, w, _ = rgb.shape
  patch_h = max(4, int(h * 0.04))
  patch_w = max(4, int(w * 0.04))
  samples = np.concatenate(
    [
      rgb[:patch_h, :patch_w].reshape(-1, 3),
      rgb[:patch_h, -patch_w:].reshape(-1, 3),
      rgb[-patch_h:, :patch_w].reshape(-1, 3),
      rgb[-patch_h:, -patch_w:].reshape(-1, 3),
    ],
    axis=0,
  )
  return np.median(samples, axis=0)


def detect_content_bbox(
  rgb: np.ndarray,
  threshold: int,
  ignore_top_ratio: float,
  ignore_bottom_ratio: float,
  padding: int,
) -> Rect:
  h, w, _ = rgb.shape
  bg = sample_background_rgb(rgb)
  distance = np.max(np.abs(rgb.astype(np.int16) - bg.astype(np.int16)), axis=2)
  mask = distance > threshold
  top_ignore = min(h, int(h * ignore_top_ratio))
  bottom_ignore = min(h, int(h * ignore_bottom_ratio))
  if top_ignore > 0:
    mask[:top_ignore, :] = False
  if bottom_ignore > 0:
    mask[h - bottom_ignore :, :] = False

  ys, xs = np.where(mask)
  if ys.size == 0 or xs.size == 0:
    return Rect(0, 0, w, h)

  rect = Rect(
    left=int(xs.min()),
    top=int(ys.min()),
    right=int(xs.max()) + 1,
    bottom=int(ys.max()) + 1,
  )
  return rect.expand(padding, w, h)


def crop_image(image: Image.Image, rect: Rect) -> Image.Image:
  return image.crop((rect.left, rect.top, rect.right, rect.bottom))


def resize_to_long_side(array: np.ndarray, long_side: int) -> np.ndarray:
  h, w = array.shape[:2]
  scale = min(1.0, long_side / max(h, w))
  new_size = (max(1, int(round(w * scale))), max(1, int(round(h * scale))))
  pil = Image.fromarray((array * 255).astype(np.uint8))
  resized = pil.resize(new_size, Image.Resampling.BICUBIC)
  return np.asarray(resized, dtype=np.float32) / 255.0


def build_signal(gray: np.ndarray, signal_threshold: float) -> np.ndarray:
  border = np.concatenate(
    [
      gray[:4, :].reshape(-1),
      gray[-4:, :].reshape(-1),
      gray[:, :4].reshape(-1),
      gray[:, -4:].reshape(-1),
    ],
    axis=0,
  )
  bg = float(np.median(border))
  signal = np.clip((bg - gray) / max(bg, 1e-3), 0.0, 1.0)
  signal[signal < signal_threshold] = 0.0
  return signal.astype(np.float32)


def build_ink_signal(gray: np.ndarray, ink_threshold: float) -> np.ndarray:
  ink_signal = build_signal(gray, signal_threshold=0.0)
  ink_signal[ink_signal < ink_threshold] = 0.0
  return ink_signal.astype(np.float32)


def center_on_canvas(source: np.ndarray, target_shape: tuple[int, int]) -> np.ndarray:
  target_h, target_w = target_shape
  canvas = np.zeros((target_h, target_w), dtype=np.float32)
  src_h, src_w = source.shape

  dest_x = max(0, (target_w - src_w) // 2)
  dest_y = max(0, (target_h - src_h) // 2)
  src_x = max(0, (src_w - target_w) // 2)
  src_y = max(0, (src_h - target_h) // 2)

  copy_w = min(target_w - dest_x, src_w - src_x)
  copy_h = min(target_h - dest_y, src_h - src_y)
  if copy_w <= 0 or copy_h <= 0:
    return canvas

  canvas[dest_y : dest_y + copy_h, dest_x : dest_x + copy_w] = source[
    src_y : src_y + copy_h,
    src_x : src_x + copy_w,
  ]
  return canvas


def translate_on_canvas(
  source: np.ndarray,
  dx: int,
  dy: int,
  target_shape: tuple[int, int],
) -> np.ndarray:
  target_h, target_w = target_shape
  canvas = np.zeros((target_h, target_w), dtype=np.float32)
  src_h, src_w = source.shape

  src_x0 = max(0, -dx)
  src_y0 = max(0, -dy)
  dst_x0 = max(0, dx)
  dst_y0 = max(0, dy)
  copy_w = min(src_w - src_x0, target_w - dst_x0)
  copy_h = min(src_h - src_y0, target_h - dst_y0)

  if copy_w <= 0 or copy_h <= 0:
    return canvas

  canvas[dst_y0 : dst_y0 + copy_h, dst_x0 : dst_x0 + copy_w] = source[
    src_y0 : src_y0 + copy_h,
    src_x0 : src_x0 + copy_w,
  ]
  return canvas


def resize_signal(signal: np.ndarray, scale: float) -> np.ndarray:
  h, w = signal.shape
  new_size = (max(1, int(round(w * scale))), max(1, int(round(h * scale))))
  pil = Image.fromarray((signal * 255).astype(np.uint8))
  resized = pil.resize(new_size, Image.Resampling.BICUBIC)
  return np.asarray(resized, dtype=np.float32) / 255.0


def phase_correlation(reference: np.ndarray, moving: np.ndarray) -> tuple[int, int]:
  reference_fft = np.fft.fft2(reference)
  moving_fft = np.fft.fft2(moving)
  cross_power = reference_fft * np.conj(moving_fft)
  magnitude = np.abs(cross_power)
  cross_power /= np.maximum(magnitude, 1e-9)
  response = np.fft.ifft2(cross_power)
  peak_y, peak_x = np.unravel_index(np.argmax(np.abs(response)), response.shape)
  h, w = reference.shape
  if peak_y > h // 2:
    peak_y -= h
  if peak_x > w // 2:
    peak_x -= w
  return int(peak_x), int(peak_y)


def compute_mask_iou(reference: np.ndarray, moving: np.ndarray) -> float:
  ref_mask = reference > 0.12
  mov_mask = moving > 0.12
  union = np.logical_or(ref_mask, mov_mask).sum()
  if union == 0:
    return 1.0
  intersection = np.logical_and(ref_mask, mov_mask).sum()
  return float(intersection / union)


def compute_signal_correlation(reference: np.ndarray, moving: np.ndarray) -> float:
  ref = reference.reshape(-1)
  mov = moving.reshape(-1)
  ref_norm = np.linalg.norm(ref)
  mov_norm = np.linalg.norm(mov)
  if ref_norm == 0 or mov_norm == 0:
    return 0.0
  return float(np.dot(ref, mov) / (ref_norm * mov_norm))


def ink_bounds(signal: np.ndarray) -> Rect | None:
  ys, xs = np.where(signal > 0.0)
  if ys.size == 0 or xs.size == 0:
    return None
  return Rect(
    left=int(xs.min()),
    top=int(ys.min()),
    right=int(xs.max()) + 1,
    bottom=int(ys.max()) + 1,
  )


def find_best_alignment(
  reference_signal: np.ndarray,
  moving_signal: np.ndarray,
  scale_min: float,
  scale_max: float,
  scale_step: float,
) -> AlignmentResult:
  best: AlignmentResult | None = None
  scale = scale_min
  while scale <= scale_max + 1e-9:
    scaled_signal = resize_signal(moving_signal, scale)
    centered = center_on_canvas(scaled_signal, reference_signal.shape)
    dx, dy = phase_correlation(reference_signal, centered)
    aligned = translate_on_canvas(centered, dx, dy, reference_signal.shape)
    iou = compute_mask_iou(reference_signal, aligned)
    corr = compute_signal_correlation(reference_signal, aligned)
    candidate = AlignmentResult(
      scale=scale,
      dx=dx,
      dy=dy,
      mask_iou=iou,
      signal_correlation=corr,
    )
    if best is None or (candidate.mask_iou, candidate.signal_correlation) > (
      best.mask_iou,
      best.signal_correlation,
    ):
      best = candidate
    scale += scale_step

  assert best is not None
  return best


def align_image_crop(
  moving_crop: Image.Image,
  reference_shape: tuple[int, int],
  scale: float,
  dx: int,
  dy: int,
) -> Image.Image:
  ref_h, ref_w = reference_shape
  scaled_w = max(1, int(round(moving_crop.width * scale)))
  scaled_h = max(1, int(round(moving_crop.height * scale)))
  scaled = moving_crop.resize((scaled_w, scaled_h), Image.Resampling.BICUBIC)
  scaled_rgb = np.asarray(scaled, dtype=np.uint8)
  background = sample_background_rgb(np.asarray(moving_crop, dtype=np.uint8)).astype(
    np.uint8,
  )

  centered = np.full((ref_h, ref_w, 3), background, dtype=np.uint8)
  dest_x = max(0, (ref_w - scaled_w) // 2)
  dest_y = max(0, (ref_h - scaled_h) // 2)
  src_x = max(0, (scaled_w - ref_w) // 2)
  src_y = max(0, (scaled_h - ref_h) // 2)
  copy_w = min(ref_w - dest_x, scaled_w - src_x)
  copy_h = min(ref_h - dest_y, scaled_h - src_y)
  if copy_w > 0 and copy_h > 0:
    centered[dest_y : dest_y + copy_h, dest_x : dest_x + copy_w] = scaled_rgb[
      src_y : src_y + copy_h,
      src_x : src_x + copy_w,
    ]

  translated = np.full_like(centered, background)
  src_x0 = max(0, -dx)
  src_y0 = max(0, -dy)
  dst_x0 = max(0, dx)
  dst_y0 = max(0, dy)
  copy_w = min(ref_w - dst_x0, ref_w - src_x0)
  copy_h = min(ref_h - dst_y0, ref_h - src_y0)
  if copy_w > 0 and copy_h > 0:
    translated[dst_y0 : dst_y0 + copy_h, dst_x0 : dst_x0 + copy_w] = centered[
      src_y0 : src_y0 + copy_h,
      src_x0 : src_x0 + copy_w,
    ]
  return Image.fromarray(translated, mode="RGB")


def compute_diff_artifacts(
  reference_crop: Image.Image,
  aligned_crop: Image.Image,
) -> tuple[dict[str, float], Image.Image, Image.Image]:
  ref = np.asarray(reference_crop, dtype=np.int16)
  aligned = np.asarray(aligned_crop, dtype=np.int16)
  abs_diff = np.abs(ref - aligned).astype(np.uint8)
  mae = float(abs_diff.mean())
  rmse = float(np.sqrt(np.mean((ref - aligned) ** 2)))
  max_error = float(abs_diff.max())

  diff_mean = abs_diff.mean(axis=2)
  highlight = np.asarray(reference_crop, dtype=np.uint8).copy()
  mismatch = diff_mean > 24
  highlight[mismatch] = np.array([230, 70, 55], dtype=np.uint8)

  diff_heat = np.zeros_like(highlight)
  diff_heat[..., 0] = np.clip(diff_mean * 3.2, 0, 255).astype(np.uint8)
  diff_heat[..., 1] = np.clip(180 - diff_mean * 2.0, 0, 255).astype(np.uint8)
  diff_heat[..., 2] = np.clip(255 - diff_mean * 3.0, 0, 255).astype(np.uint8)

  return (
    {
      "rgb_mae": mae,
      "rgb_rmse": rmse,
      "max_channel_error": max_error,
    },
    Image.fromarray(highlight, mode="RGB"),
    Image.fromarray(diff_heat, mode="RGB"),
  )


def estimate_line_centers(signal: np.ndarray) -> list[int]:
  projection = signal.sum(axis=1)
  if projection.size == 0:
    return []
  window = np.ones(5, dtype=np.float32) / 5.0
  smooth = np.convolve(projection, window, mode="same")
  non_zero = smooth[smooth > 0]
  if non_zero.size == 0:
    return []

  threshold = max(1.0, float(np.percentile(non_zero, 72)))
  min_distance = max(12, int(signal.shape[0] * 0.035))
  peaks: list[int] = []
  for idx in range(1, len(smooth) - 1):
    current = smooth[idx]
    if current < threshold:
      continue
    if current < smooth[idx - 1] or current < smooth[idx + 1]:
      continue
    if peaks and idx - peaks[-1] < min_distance:
      if current > smooth[peaks[-1]]:
        peaks[-1] = idx
      continue
    peaks.append(idx)
  return peaks


def compute_line_metrics(reference_signal: np.ndarray, moving_signal: np.ndarray) -> dict[str, object]:
  ref_centers = estimate_line_centers(reference_signal)
  mov_centers = estimate_line_centers(moving_signal)
  paired = min(len(ref_centers), len(mov_centers))
  if paired == 0:
    return {
      "reference_line_centers": ref_centers,
      "aligned_line_centers": mov_centers,
      "mean_center_error_px": None,
      "mean_spacing_error_px": None,
    }

  center_error = float(
    np.mean([abs(ref_centers[i] - mov_centers[i]) for i in range(paired)])
  )
  spacing_pairs = max(0, paired - 1)
  if spacing_pairs == 0:
    spacing_error = None
  else:
    ref_spacings = np.diff(ref_centers[:paired])
    mov_spacings = np.diff(mov_centers[:paired])
    spacing_error = float(np.mean(np.abs(ref_spacings - mov_spacings)))

  return {
    "reference_line_centers": ref_centers,
    "aligned_line_centers": mov_centers,
    "mean_center_error_px": center_error,
    "mean_spacing_error_px": spacing_error,
  }


def build_side_by_side(reference: Image.Image, aligned: Image.Image) -> Image.Image:
  width = reference.width + aligned.width
  height = max(reference.height, aligned.height)
  canvas = Image.new("RGB", (width, height), color=(255, 255, 255))
  canvas.paste(reference, (0, 0))
  canvas.paste(aligned, (reference.width, 0))
  return canvas


def write_image(path: Path, image: Image.Image) -> None:
  path.parent.mkdir(parents=True, exist_ok=True)
  image.save(path)


def main() -> None:
  args = parse_args()
  tilawa_path, ayah_path = resolve_pair(args)
  output_dir = args.output_dir.resolve()
  output_dir.mkdir(parents=True, exist_ok=True)

  tilawa_image = load_rgb(tilawa_path)
  ayah_image = load_rgb(ayah_path)

  tilawa_bbox = detect_content_bbox(
    image_to_rgb_array(tilawa_image),
    threshold=args.crop_threshold,
    ignore_top_ratio=args.ignore_top_ratio,
    ignore_bottom_ratio=args.ignore_bottom_ratio,
    padding=args.crop_padding,
  )
  ayah_bbox = detect_content_bbox(
    image_to_rgb_array(ayah_image),
    threshold=args.crop_threshold,
    ignore_top_ratio=args.ignore_top_ratio,
    ignore_bottom_ratio=args.ignore_bottom_ratio,
    padding=args.crop_padding,
  )

  tilawa_crop = crop_image(tilawa_image, tilawa_bbox)
  ayah_crop = crop_image(ayah_image, ayah_bbox)

  tilawa_signal = build_signal(
    resize_to_long_side(image_to_gray_array(tilawa_crop), args.analysis_long_side),
    signal_threshold=args.signal_threshold,
  )
  ayah_signal = build_signal(
    resize_to_long_side(image_to_gray_array(ayah_crop), args.analysis_long_side),
    signal_threshold=args.signal_threshold,
  )

  alignment = find_best_alignment(
    reference_signal=ayah_signal,
    moving_signal=tilawa_signal,
    scale_min=args.scale_min,
    scale_max=args.scale_max,
    scale_step=args.scale_step,
  )

  coarse_ratio = max(ayah_crop.size) / max(ayah_signal.shape)
  full_dx = int(round(alignment.dx * coarse_ratio))
  full_dy = int(round(alignment.dy * coarse_ratio))

  aligned_crop = align_image_crop(
    moving_crop=tilawa_crop,
    reference_shape=(ayah_crop.height, ayah_crop.width),
    scale=alignment.scale,
    dx=full_dx,
    dy=full_dy,
  )

  ref_signal_full = build_signal(
    image_to_gray_array(ayah_crop),
    signal_threshold=args.signal_threshold,
  )
  aligned_signal_full = build_signal(
    image_to_gray_array(aligned_crop),
    signal_threshold=args.signal_threshold,
  )
  ref_ink_signal = build_ink_signal(
    image_to_gray_array(ayah_crop),
    ink_threshold=args.ink_threshold,
  )
  aligned_ink_signal = build_ink_signal(
    image_to_gray_array(aligned_crop),
    ink_threshold=args.ink_threshold,
  )

  pixel_metrics, diff_overlay, diff_heatmap = compute_diff_artifacts(
    ayah_crop,
    aligned_crop,
  )
  line_metrics = compute_line_metrics(ref_ink_signal, aligned_ink_signal)
  ref_ink_bbox = ink_bounds(ref_ink_signal)
  aligned_ink_bbox = ink_bounds(aligned_ink_signal)

  metrics = {
    "tilawa_path": str(tilawa_path),
    "ayah_path": str(ayah_path),
    "tilawa_bbox": asdict(tilawa_bbox),
    "ayah_bbox": asdict(ayah_bbox),
    "alignment": asdict(alignment),
    "alignment_full_resolution": {
      "dx": full_dx,
      "dy": full_dy,
      "scale": alignment.scale,
    },
    "pixel_metrics": pixel_metrics,
    "ink_bounds": {
      "reference": asdict(ref_ink_bbox) if ref_ink_bbox else None,
      "aligned": asdict(aligned_ink_bbox) if aligned_ink_bbox else None,
    },
    "signal_metrics": {
      "full_signal_correlation": compute_signal_correlation(
        ref_signal_full,
        aligned_signal_full,
      ),
      "full_mask_iou": compute_mask_iou(ref_signal_full, aligned_signal_full),
    },
    "line_metrics": line_metrics,
  }

  write_image(output_dir / "tilawa_crop.png", tilawa_crop)
  write_image(output_dir / "ayah_crop.png", ayah_crop)
  write_image(output_dir / "tilawa_aligned.png", aligned_crop)
  write_image(output_dir / "diff_overlay.png", diff_overlay)
  write_image(output_dir / "diff_heatmap.png", diff_heatmap)
  write_image(output_dir / "side_by_side.png", build_side_by_side(ayah_crop, aligned_crop))
  (output_dir / "metrics.json").write_text(
    json.dumps(metrics, indent=2, ensure_ascii=False),
    encoding="utf-8",
  )
  print(json.dumps(metrics, indent=2, ensure_ascii=False))


if __name__ == "__main__":
  main()
