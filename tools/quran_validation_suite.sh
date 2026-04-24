#!/usr/bin/env bash

# Quran Validation Suite
# Automatically discovers screenshot pairs and runs quran_page_compare.py across all of them.

set -e

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCREENSHOTS_DIR="${WORKSPACE_DIR}/screenshots"
OUTPUT_DIR="${WORKSPACE_DIR}/build/quran_validation_reports"
COMPARE_SCRIPT="${WORKSPACE_DIR}/tools/quran_page_compare.py"

mkdir -p "$OUTPUT_DIR"

echo "================================================="
echo " Starting Quran Validation Suite"
echo "================================================="
echo "Looking for screenshot pairs in: $SCREENSHOTS_DIR"

# Find unique pair keys based on tilawa_*.png prefix
if [ ! -d "$SCREENSHOTS_DIR" ]; then
  echo "Error: Screenshots directory not found at $SCREENSHOTS_DIR"
  exit 1
fi

declare -a PAIR_KEYS=()

for f in "$SCREENSHOTS_DIR"/tilawa_*.png; do
  if [ -e "$f" ]; then
    # Extract everything after 'tilawa_' and before '.png'
    basename_ext=$(basename "$f")
    pair_key="${basename_ext#tilawa_}"
    pair_key="${pair_key%.png}"
    
    # Check if corresponding ayah_app image exists
    if ls "$SCREENSHOTS_DIR"/ayah_app_${pair_key}.* 1> /dev/null 2>&1; then
      PAIR_KEYS+=("$pair_key")
    else
      echo "Warning: No matching Ayah app screenshot for pair key '$pair_key'."
    fi
  fi
done

if [ ${#PAIR_KEYS[@]} -eq 0 ]; then
  echo "No matching screenshot pairs found. Ensure screenshots/ contains tilawa_<key>.png and ayah_app_<key>.png files."
  exit 0
fi

echo "Found ${#PAIR_KEYS[@]} pairs to validate."

# Generate HTML Report Wrapper
REPORT_HTML="$OUTPUT_DIR/validation_report.html"
cat <<EOF > "$REPORT_HTML"
<!DOCTYPE html>
<html>
<head>
    <title>Quran Validation Suite Report</title>
    <style>
        body { font-family: sans-serif; background: #121212; color: #fff; margin: 2rem; }
        .card { background: #1e1e1e; border-radius: 8px; padding: 1.5rem; margin-bottom: 2rem; box-shadow: 0 4px 6px rgba(0,0,0,0.3); }
        h1, h2, h3 { color: #f2f2f2; }
        table { border-collapse: collapse; width: 100%; margin-top: 1rem; }
        th, td { text-align: left; padding: 8px; border-bottom: 1px solid #333; }
        th { background-color: #2c2c2c; }
        .success { color: #4caf50; }
        .warning { color: #ff9800; }
        .error { color: #f44336; }
        img { max-width: 100%; height: auto; border: 1px solid #333; margin-top: 10px;}
        .img-grid { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px; }
    </style>
</head>
<body>
    <h1>Quran Match Validation Report</h1>
    <p>Generated on $(date)</p>
EOF

for key in "${PAIR_KEYS[@]}"; do
  echo "-------------------------------------------------"
  echo "Validating: $key"
  
  pair_output_dir="$OUTPUT_DIR/$key"
  mkdir -p "$pair_output_dir"
  
  # Run the python script
  # We pipe output to jq to extract key metrics to display in HTML
  json_output=$(python3 "$COMPARE_SCRIPT" \
    --screenshots-dir "$SCREENSHOTS_DIR" \
    --pair-key "$key" \
    --output-dir "$pair_output_dir" 2>&1)
  
  if [ $? -ne 0 ]; then
    echo "Python script failed for pair '$key':"
    echo "$json_output"
    continue
  fi

  # Basic jq parsing if available
  scale=$(echo "$json_output" | jq '.alignment.scale' 2>/dev/null || echo "N/A")
  mask_iou=$(echo "$json_output" | jq '.alignment.mask_iou' 2>/dev/null || echo "N/A")
  line_error=$(echo "$json_output" | jq '.line_metrics.mean_center_error_px' 2>/dev/null || echo "N/A")

  # Add to HTML
  cat <<EOF >> "$REPORT_HTML"
  <div class="card">
      <h2>Device / Page Key: ${key}</h2>
      <table>
          <tr><th>Metric</th><th>Value</th></tr>
          <tr><td>Scale Match</td><td>${scale}</td></tr>
          <tr><td>Mask IoU (Alignment Quality)</td><td>${mask_iou}</td></tr>
          <tr><td>Mean Line Center Error (px)</td><td>${line_error}</td></tr>
      </table>
      
      <h3>Visual Diffs</h3>
      <div class="img-grid">
          <div>
            <h4>Side-by-Side Reference</h4>
            <a href="${key}/side_by_side.png" target="_blank">
              <img src="${key}/side_by_side.png" alt="Side by Side" />
            </a>
          </div>
          <div>
            <h4>Structural Diff Overlay</h4>
            <a href="${key}/diff_overlay.png" target="_blank">
              <img src="${key}/diff_overlay.png" alt="Diff Overlay" />
            </a>
          </div>
          <div>
            <h4>Threshold Heatmap</h4>
            <a href="${key}/diff_heatmap.png" target="_blank">
              <img src="${key}/diff_heatmap.png" alt="Heatmap" />
            </a>
          </div>
      </div>
  </div>
EOF

done

cat <<EOF >> "$REPORT_HTML"
</body>
</html>
EOF

echo "================================================="
echo " Validation complete! Report generated at:"
echo " file://$REPORT_HTML"
echo "================================================="
