#!/bin/zsh

# Enable dry-run mode by passing --dry-run
DRY_RUN=false
[[ "$1" == "--dry-run" ]] && DRY_RUN=true && echo "🔍 Running in dry-run mode..."

SOURCE_DIR="/sdcard/DCIM/Camera"
typeset -A COUNTS_PHOTOS
typeset -A COUNTS_VIDEOS
typeset -A MISSING_DIRS
TOTAL_PHOTOS=0
TOTAL_VIDEOS=0

for YEAR in {2021..2026}; do
  for MONTH in {01..12}; do
    MONTH_INT=$((10#$MONTH))  
    QUARTER=$(( (MONTH_INT - 1) / 3 + 1 ))
    PREFIX="${YEAR}${MONTH}"
    TARGET_DIR="$SOURCE_DIR/$YEAR/q$QUARTER"
    KEY="${YEAR}/q${QUARTER}"

    # Count photos (jpg/jpeg)
    COUNT_PHOTOS=$(adb shell "ls '$SOURCE_DIR/$PREFIX'*.jpg '$SOURCE_DIR/$PREFIX'*.jpeg '$SOURCE_DIR/$PREFIX'*.heic 2>/dev/null | wc -l" | tr -d '\r')
    if [[ "$COUNT_PHOTOS" -gt 0 ]]; then
      TOTAL_PHOTOS=$((TOTAL_PHOTOS + COUNT_PHOTOS))
      COUNTS_PHOTOS[$KEY]=$(( ${COUNTS_PHOTOS[$KEY]:-0} + COUNT_PHOTOS ))

      if [[ "$DRY_RUN" == false ]]; then
        adb shell "mkdir -p '$TARGET_DIR/photos-${YEAR}-q${QUARTER}'"
        adb shell "mv '$SOURCE_DIR/$PREFIX'*.jpg '$SOURCE_DIR/$PREFIX'*.jpeg '$SOURCE_DIR/$PREFIX'*.heic '$TARGET_DIR/photos-${YEAR}-q${QUARTER}/' 2>/dev/null"
      else
        MISSING_DIRS["$KEY/photos-${YEAR}-q${QUARTER}"]=1
      fi
    fi

    # Count videos (mp4, mov, etc.)
    COUNT_VIDEOS=$(adb shell "ls '$SOURCE_DIR/$PREFIX'*.mp4 '$SOURCE_DIR/$PREFIX'*.mov 2>/dev/null | wc -l" | tr -d '\r')
    if [[ "$COUNT_VIDEOS" -gt 0 ]]; then
      TOTAL_VIDEOS=$((TOTAL_VIDEOS + COUNT_VIDEOS))
      COUNTS_VIDEOS[$KEY]=$(( ${COUNTS_VIDEOS[$KEY]:-0} + COUNT_VIDEOS ))

      if [[ "$DRY_RUN" == false ]]; then
        adb shell "mkdir -p '$TARGET_DIR/videos-${YEAR}-q${QUARTER}'"
        adb shell "mv '$SOURCE_DIR/$PREFIX'*.mp4 '$SOURCE_DIR/$PREFIX'*.mov '$TARGET_DIR/videos-${YEAR}-q${QUARTER}/' 2>/dev/null"
      else
        MISSING_DIRS["$KEY/videos-${YEAR}-q${QUARTER}"]=1
      fi
    fi
  done
done

echo "\n📊 Summary:"
echo "-----------"
for KEY in ${(k)COUNTS_PHOTOS}; do
  echo "$KEY → ${COUNTS_PHOTOS[$KEY]} photos"
done
for KEY in ${(k)COUNTS_VIDEOS}; do
  echo "$KEY → ${COUNTS_VIDEOS[$KEY]} videos"
done

if (( ${#MISSING_DIRS[@]} > 0 )); then
  echo "\n⚠️ Missing target subdirectories (would be created):"
  for KEY in ${(k)MISSING_DIRS}; do
    echo "$SOURCE_DIR/$KEY/"
  done
fi

echo "\nTotal photos matched: $TOTAL_PHOTOS"
echo "Total videos matched: $TOTAL_VIDEOS"
[[ "$DRY_RUN" == true ]] && echo "✅ Dry-run complete. No files were moved." || echo "✅ Files organized successfully."
