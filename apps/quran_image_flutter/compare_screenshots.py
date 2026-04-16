#!/usr/bin/env python3
"""
Visual Perfectionist - Screenshot Comparison Tool
Compares two screenshots and generates a detailed pixel-diff board.
"""

import cv2
import numpy as np
import argparse
import os
from pathlib import Path

def compare_images(ref_path, test_path, output_path, crop_status_bar=True):
    # Load images
    ref = cv2.imread(ref_path)
    test = cv2.imread(test_path)
    
    if ref is None or test is None:
        print(f"Error: Could not load images. Check paths:\nRef: {ref_path}\nTest: {test_path}")
        return

    # Resize test to match reference if they differ
    if ref.shape[:2] != test.shape[:2]:
        print(f"Warning: Resolutions differ. Resizing test ({test.shape[1]}x{test.shape[0]}) to match reference ({ref.shape[1]}x{ref.shape[0]})")
        test = cv2.resize(test, (ref.shape[1], ref.shape[0]), interpolation=cv2.INTER_CUBIC)

    # Optional: Crop status bar (top 8%) and bottom nav (bottom 8%) to focus on content
    if crop_status_bar:
        h_orig, w_orig = ref.shape[:2]
        crop_h = int(h_orig * 0.08)
        ref = ref[crop_h:h_orig-crop_h, :]
        test = test[crop_h:h_orig-crop_h, :]
    
    h, w = ref.shape[:2]

    # 1. Absolute Difference
    diff = cv2.absdiff(ref, test)
    
    # 2. Binary Diff (Thresholded)
    gray_diff = cv2.cvtColor(diff, cv2.COLOR_BGR2GRAY)
    _, binary_diff = cv2.threshold(gray_diff, 10, 255, cv2.THRESH_BINARY)
    
    # 3. Heatmap
    # Highlight differences in bright Magenta on top of reference
    heatmap = ref.copy()
    heatmap[binary_diff > 0] = [255, 0, 255] # Magenta highlights

    # 4. SSIM (Simplified version for quick run)
    score = np.mean(gray_diff)
    similarity = 100 - (score / 2.55) # Approx similarity percentage

    # Create Comparison Board (2x2 Grid)
    h, w = ref.shape[:2]
    # Spacing parameters
    h_pad = 20
    w_pad = 20
    top_margin = 100
    
    board = np.zeros((top_margin + h * 2 + h_pad * 3, w * 2 + w_pad * 3, 3), dtype=np.uint8)
    
    # Add title and metrics
    cv2.putText(board, f"Visual Perfectionist Analysis - Similarity: {similarity:.2f}%", 
                (50, 60), cv2.FONT_HERSHEY_SIMPLEX, 1.2, (255, 255, 255), 2)

    # Labels
    font = cv2.FONT_HERSHEY_SIMPLEX
    lbl_color = (255, 255, 0)
    
    def add_img(img, row, col, title):
        y_start = top_margin + row * h + row * h_pad
        x_start = col * w + col * w_pad
        if len(img.shape) == 2:
            img = cv2.cvtColor(img, cv2.COLOR_BGR2BGR) # Dummy but ensuring 3 channels if it was gray
        
        # Ensure we don't go out of bounds
        board[y_start:y_start+h, x_start:x_start+w] = img
        cv2.putText(board, title, (x_start + 20, y_start + 50), font, 1.0, lbl_color, 2)

    add_img(ref, 0, 0, "REFERENCE (Ayah App)")
    add_img(test, 0, 1, "TEST (Your App)")
    add_img(cv2.cvtColor(binary_diff, cv2.COLOR_GRAY2BGR), 1, 0, "PIXEL DIFF (Binary)")
    add_img(heatmap, 1, 1, "HEATMAP (Discrepancies)")

    # Save output
    cv2.imwrite(output_path, board)
    print(f"Comparison report saved to: {output_path}")
    print(f"Similarity Score: {similarity:.2f}%")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Compare two screenshots for visual parity.")
    parser.add_argument("--ref", required=True, help="Path to reference screenshot (ground truth)")
    parser.add_argument("--test", required=True, help="Path to test screenshot (your app)")
    parser.add_argument("--out", default="comparison_report.png", help="Output report filename")
    parser.add_argument("--no-crop", action="store_false", dest="crop", help="Disable auto-cropping of system bars")
    
    args = parser.parse_args()
    
    compare_images(args.ref, args.test, args.out, args.crop)
