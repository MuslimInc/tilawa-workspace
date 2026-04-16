#!/usr/bin/env python3
"""
Marker Auditor - Guided Precision Validator
Uses JSON positions as a guide to find and compare markers in screenshots.
"""

import cv2
import numpy as np
import argparse
import math
import json
from pathlib import Path

def get_all_circles(img):
    """Detects all potential markers in the image."""
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(gray, (5, 5), 0)
    circles = cv2.HoughCircles(blur, cv2.HOUGH_GRADIENT, dp=1.0, minDist=25,
                               param1=50, param2=20, minRadius=10, maxRadius=25)
    if circles is None:
        return []
    return [(float(x), float(y)) for x, y, r in circles[0]]

def audit(ref_path, test_path, json_path, output_path):
    # Load JSON data
    with open(json_path, "r") as f:
        meta_markers = json.load(f)
        
    # Load images
    ref = cv2.imread(str(ref_path))
    test = cv2.imread(str(test_path))
    
    if ref is None or test is None:
        print("Error: Could not load images.")
        return

    rw, rh = ref.shape[1], ref.shape[0]
    tw, th = test.shape[1], test.shape[0]
    
    ref_all = get_all_circles(ref)
    test_all = get_all_circles(test)

    canvas = test.copy()
    
    print("\n" + "="*95)
    print(f"{'Verse':<10} | {'Line':<5} | {'Ref (X,Y)':<15} | {'Test (X,Y)':<15} | {'Drift (px)':<10} | {'Status'}")
    print("-" * 95)

    total_drift = 0
    count = 0

    for m in meta_markers:
        key = f"{m['sura']}:{m['ayah']}"
        line = m['line']
        json_x_ratio = m['centerX']
        
        # Guide positions
        target_rx = json_x_ratio * rw
        target_tx = json_x_ratio * tw
        
        # Match nearest detected circle in Ref
        # We search within a wide vertical range but strict horizontal range
        def find_best_match(circles, tx, line_hint, h_orig):
            best = None
            min_score = 9999
            for cx, cy in circles:
                # Vertical heuristic: estimate Y roughly but allow flexibility
                # The line sequence is more important than absolute pixel position
                est_y = (line_hint) * (h_orig / 15.0) 
                dx = abs(cx - tx)
                dy = abs(cy - (h_orig * line_hint / 15.0)) # Rough line guess
                
                # Weight horizontal drift heavily for pairing
                score = dx * 2.0 + abs(dy - 100) # (Wait, 100 is just a padding guess)
                
                # Dynamic matching: Pick the circle closest to the centerX
                if dx < 30 and (best is None or dx < min_score):
                    min_score = dx
                    best = (cx, cy)
            return best

        ref_c = find_best_match(ref_all, target_rx, line, rh)
        test_c = find_best_match(test_all, target_tx, line, th)
        
        if ref_c and test_c:
            rx, ry = ref_c
            tx, ty = test_c
            
            dx = tx - rx
            dy = ty - ry
            drift = math.sqrt(dx**2 + dy**2)
            
            total_drift += drift
            count += 1
            
            status = "PERFECT" if drift < 1.0 else "DRIFTING"
            if drift > 4.0: status = "CRITICAL"
            
            print(f"{key:<10} | {line:<5} | ({rx:>5.1f}, {ry:>5.1f}) | ({tx:>5.1f}, {ty:>5.1f}) | {drift:>10.2f} | {status}")
            
            # Visual feedback on canvas
            cv2.circle(canvas, (int(rx), int(ry)), 18, (0, 255, 0), 2) # Reference Target
            cv2.circle(canvas, (int(tx), int(ty)), 4, (0, 0, 255), -1) # Actual Center
            cv2.line(canvas, (int(rx), int(ry)), (int(tx), int(ty)), (255, 255, 0), 2) # Deviation
            cv2.putText(canvas, key, (int(tx)+20, int(ty)), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
        else:
            print(f"{key:<10} | {line:<5} | {'[MATCH NOT FOUND]':<35} | -          | MISSING")

    avg_drift = total_drift / count if count > 0 else 0
    print("="*95)
    print(f"Audit Complete. Average Marker Drift: {avg_drift:.2f}px")
    cv2.imwrite(output_path, canvas)
    print(f"Deviation map saved to: {output_path}")

    avg_drift = total_drift / count if count > 0 else 0
    print("="*90)
    print(f"Audit Complete. Average Marker Drift: {avg_drift:.2f}px")
    cv2.imwrite(output_path, canvas)
    print(f"Deviation map saved to: {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Guided Audit for Quran marker positions.")
    parser.add_argument("--ref", required=True, help="Path to reference screenshot")
    parser.add_argument("--test", required=True, help="Path to your app screenshot")
    parser.add_argument("--json", required=True, help="Path to 604.json metadata")
    parser.add_argument("--out", default="guided_marker_audit.png", help="Output path for map")
    
    args = parser.parse_args()
    audit(args.ref, args.test, args.json, args.out)
