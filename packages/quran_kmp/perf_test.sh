#!/bin/bash
# Quran KMP Performance Test
# Simulates page swipes and captures gfxinfo frame data

PACKAGE="com.tilawa.quran.kmp"
ACTIVITY="$PACKAGE/.MainActivity"

echo "=== Quran KMP Jank / Frame Performance Test ==="
echo ""

# Start fresh
adb shell am start -n "$ACTIVITY" > /dev/null
sleep 2

# Reset stats
adb shell dumpsys gfxinfo "$PACKAGE" reset > /dev/null
echo "[1/3] Simulating 20 page swipes (left = next page in RTL)..."

# Swipe left to go forward (RTL layout, reverseLayout=true means left = next)
for i in $(seq 1 20); do
    adb shell input swipe 800 1000 200 1000 300
    sleep 0.6
done

echo "[2/3] Swiping back..."
for i in $(seq 1 10); do
    adb shell input swipe 200 1000 800 1000 300
    sleep 0.6
done

echo "[3/3] Collecting frame data..."
echo ""

GFXINFO=$(adb shell dumpsys gfxinfo "$PACKAGE")

# Extract the summary section
echo "--- Frame Stats Summary ---"
echo "$GFXINFO" | grep -E "Total frames|Janky frames|50th|90th|95th|99th|Number Missed|Slow UI|Slow bitmap|Slow issue"

echo ""
echo "--- Raw Frame Histogram ---"
echo "$GFXINFO" | grep -A 60 "Profile data in ms" | head -65

echo ""
echo "--- Jank Analysis ---"
JANKY=$(echo "$GFXINFO" | grep "Janky frames" | grep -oE '[0-9]+' | head -1)
TOTAL=$(echo "$GFXINFO" | grep "Total frames" | grep -oE '[0-9]+' | head -1)

if [ -n "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
    echo "Janky frames : $JANKY / $TOTAL"
    PERCENT=$(echo "scale=1; $JANKY * 100 / $TOTAL" | bc)
    echo "Jank rate    : $PERCENT%"
    if (( $(echo "$PERCENT < 5" | bc -l) )); then
        echo "Result       : GOOD (< 5% jank)"
    elif (( $(echo "$PERCENT < 15" | bc -l) )); then
        echo "Result       : ACCEPTABLE (5-15% jank)"
    else
        echo "Result       : NEEDS WORK (> 15% jank)"
    fi
else
    echo "No frame data captured — ensure the app is visible and active during the test."
fi
