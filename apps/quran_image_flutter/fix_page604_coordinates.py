#!/usr/bin/env python3
"""
fix_page604_coordinates.py

Fixes page 604 marker coordinates by using Ayah app ground truth for X.
Y positions use the proven line-based formula.
"""

import json
from pathlib import Path

COORDS_FILE = Path("apps/quran_image_flutter/assets/data/verse_marker_coordinates.json")
AYAHINFO_FILE = Path("apps/quran_image_flutter/assets/data/ayahinfo_markers.json")
PAGE = "604"


def main():
    print("=" * 70)
    print("Fixing Page 604 Coordinates")
    print("=" * 70)
    
    # Load current coordinates
    with open(COORDS_FILE) as f:
        all_coords = json.load(f)
    
    current = all_coords.get(PAGE, [])
    print(f"\nLoaded {len(current)} current markers for page {PAGE}")
    
    # Load Ayah info ground truth
    with open(AYAHINFO_FILE) as f:
        ayahinfo = json.load(f)
    
    ayah_markers = ayahinfo.get(PAGE, [])
    print(f"Loaded {len(ayah_markers)} ground truth markers")
    
    # Build lookup for ayahinfo markers by (sura, ayah)
    ayah_lookup = {}
    for m in ayah_markers:
        key = (m['s'], m['a'])
        ayah_lookup[key] = m
    
    # Generate fixed coordinates
    fixed = []
    
    print(f"\n{'='*70}")
    print("Applying fixes:")
    print(f"{'='*70}")
    print(f"{'Sura':>4} {'Ayah':>4} | {'Old X':>8} {'New X':>8} {'Change':>8}")
    print("-" * 70)
    
    for m in current:
        key = (m['sura'], m['ayah'])
        old_x = m['centerX']
        
        if key in ayah_lookup:
            # Use ground truth X from Ayah app
            new_x = round(ayah_lookup[key]['x'], 6)
            
            # Keep the line mapping (which was verified correct)
            line = m['line']
            
            change = (new_x - old_x) * 100
            marker = "  " if abs(change) < 1 else "**"
            print(f"{marker} {key[0]:4d} {key[1]:4d} | {old_x:8.4f} {new_x:8.4f} {change:+7.2f}%")
            
            fixed.append({
                'sura': m['sura'],
                'ayah': m['ayah'],
                'line': line,
                'centerX': new_x,
            })
        else:
            print(f"?? {key[0]:4d} {key[1]:4d} | {old_x:8.4f} {'N/A':>8} {'N/A':>7}")
            # Keep original if no ground truth
            fixed.append(m)
    
    # Update coordinates
    all_coords[PAGE] = fixed
    
    # Save back
    with open(COORDS_FILE, 'w') as f:
        json.dump(all_coords, f, separators=(',', ':'))
    
    print(f"\n{'='*70}")
    print(f"✓ Saved fixed coordinates to {COORDS_FILE}")
    print(f"{'='*70}")
    
    # Verify
    print(f"\nVerification - first 5 fixed markers:")
    for m in fixed[:5]:
        print(f"  Sura {m['sura']}, Ayah {m['ayah']}: line={m['line']}, centerX={m['centerX']:.4f}")
    
    print(f"\nNext steps:")
    print(f"  1. Hot restart the Flutter app")
    print(f"  2. Navigate to page 604")
    print(f"  3. Verify markers align with text endings")


if __name__ == "__main__":
    main()
