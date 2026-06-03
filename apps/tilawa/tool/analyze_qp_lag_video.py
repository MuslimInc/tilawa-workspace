#!/usr/bin/env python3
"""Extract frames from qp_lag.webm and report frame-to-frame spikes (jank proxy)."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'pillow', '-q'])
    from PIL import Image


def avg_diff(a: Path, b: Path, step: int = 8) -> float:
    pa, pb = Image.open(a).convert('RGB'), Image.open(b).convert('RGB')
    if pa.size != pb.size:
        pb = pb.resize(pa.size)
    w, h = pa.size
    total = 0.0
    count = 0
    for y in range(0, h, step):
        for x in range(0, w, step):
            px, py = pa.getpixel((x, y)), pb.getpixel((x, y))
            total += sum(abs(px[i] - py[i]) for i in range(3))
            count += 1
    return total / (count * 3)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--video',
        type=Path,
        default=Path(__file__).resolve().parents[2]
        / 'screenshots/videos/qp_lag.webm',
    )
    parser.add_argument('--fps', type=float, default=4)
    parser.add_argument('--width', type=int, default=360)
    parser.add_argument('--top', type=int, default=20, help='Report top N spikes')
    args = parser.parse_args()

    out_dir = args.video.parent / f'{args.video.stem}_frames'
    out_dir.mkdir(parents=True, exist_ok=True)

    pattern = str(out_dir / 'frame_%05d.jpg')
    subprocess.run(
        [
            'ffmpeg',
            '-y',
            '-i',
            str(args.video),
            '-vf',
            f'fps={args.fps},scale={args.width}:-1',
            '-q:v',
            '3',
            pattern,
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    paths = sorted(out_dir.glob('frame_*.jpg'))
    if len(paths) < 2:
        print('Not enough frames extracted', file=sys.stderr)
        return 1

    diffs: list[tuple[int, float, str]] = []
    for i in range(1, len(paths)):
        d = avg_diff(paths[i - 1], paths[i])
        diffs.append((i, d, paths[i].name))

    diffs.sort(key=lambda t: t[1], reverse=True)
    median = sorted(d for _, d, _ in diffs)[len(diffs) // 2]
    thresh = max(12.0, median * 2.5)
    interval = 1.0 / args.fps

    print(f'video={args.video.name} frames={len(paths)} fps={args.fps}')
    print(f'median_diff={median:.2f} spike_threshold={thresh:.2f}')
    print(f'frames_dir={out_dir}')
    print('\nTop spikes (likely layer swaps / animation jumps):')
    for i, d, name in diffs[: args.top]:
        print(f'  t={i * interval:6.2f}s diff={d:6.2f} {name}')

    spikes = [t for t in diffs if t[1] >= thresh]
    print(f'\nSpikes >= threshold: {len(spikes)}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
