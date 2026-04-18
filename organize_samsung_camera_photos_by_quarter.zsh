#!/bin/zsh

# Enable dry-run mode by passing --dry-run
DRY_RUN=false
[[ "$1" == "--dry-run" ]] && DRY_RUN=true && echo "🔍 Running in dry-run mode..."

SOURCE_DIR_CAMERA="/sdcard/DCIM/Camera"
SOURCE_DIR_META="/sdcard/Download/Meta AI"
typeset -A COUNTS_PHOTOS
typeset -A COUNTS_VIDEOS
typeset -A MISSING_DIRS
TOTAL_PHOTOS=0
TOTAL_VIDEOS=0

# Store Meta path separately to avoid space issues
META_PATH="/sdcard/Download/Meta AI"

for YEAR in {2021..2026}; do
  for MONTH in {01..12}; do
    MONTH_INT=$((10#$MONTH))  
    QUARTER=$(( (MONTH_INT - 1) / 3 + 1 ))
    PREFIX="${YEAR}${MONTH}"
    TARGET_DIR_CAMERA="$SOURCE_DIR_CAMERA/$YEAR/q$QUARTER"
    TARGET_DIR_META="$SOURCE_DIR_META/$YEAR/q$QUARTER"
    KEY="${YEAR}/q${QUARTER}"

    # Count photos from Camera folder
    COUNT_PHOTOS_CAMERA=$(adb shell "ls '$SOURCE_DIR_CAMERA/$PREFIX'*.jpg '$SOURCE_DIR_CAMERA/$PREFIX'*.jpeg '$SOURCE_DIR_CAMERA/$PREFIX'*.heic '$SOURCE_DIR_CAMERA/IMG_${YEAR}${MONTH}'*.jpg '$SOURCE_DIR_CAMERA/IMG_${YEAR}${MONTH}'*.jpeg '$SOURCE_DIR_CAMERA/IMG_${YEAR}${MONTH}'*.heic 2>/dev/null | wc -l" | tr -d '\r')
    
    # Count videos from Camera folder
    COUNT_VIDEOS_CAMERA=$(adb shell "ls '$SOURCE_DIR_CAMERA/$PREFIX'*.mp4 '$SOURCE_DIR_CAMERA/$PREFIX'*.mov '$SOURCE_DIR_CAMERA/VID_${YEAR}${MONTH}'*.mp4 '$SOURCE_DIR_CAMERA/VID_${YEAR}${MONTH}'*.mov 2>/dev/null | wc -l" | tr -d '\r')
    
    # Count photos from Meta AI folder - using META_PATH variable
    COUNT_PHOTOS_META=$(adb shell "ls '$META_PATH/${YEAR}${MONTH}'*.jpg 2>/dev/null | wc -l" | tr -d '\r')
    
    # Count videos from Meta AI folder
    COUNT_VIDEOS_META=$(adb shell "ls '$META_PATH/${YEAR}${MONTH}'*.mp4 2>/dev/null | wc -l" | tr -d '\r')
    
    # Calculate totals
    COUNT_PHOTOS=$((COUNT_PHOTOS_CAMERA + COUNT_PHOTOS_META))
    COUNT_VIDEOS=$((COUNT_VIDEOS_CAMERA + COUNT_VIDEOS_META))
    
    # Handle photos
    if [[ "$COUNT_PHOTOS" -gt 0 ]]; then
      TOTAL_PHOTOS=$((TOTAL_PHOTOS + COUNT_PHOTOS))
      COUNTS_PHOTOS[$KEY]=$(( ${COUNTS_PHOTOS[$KEY]:-0} + COUNT_PHOTOS ))

      if [[ "$DRY_RUN" == false ]]; then
        # Handle Camera photos
        if [[ "$COUNT_PHOTOS_CAMERA" -gt 0 ]]; then
          adb shell "mkdir -p '$TARGET_DIR_CAMERA/photos-${YEAR}-q${QUARTER}'"
          adb shell "mv '$SOURCE_DIR_CAMERA/$PREFIX'*.jpg '$SOURCE_DIR_CAMERA/$PREFIX'*.jpeg '$SOURCE_DIR_CAMERA/$PREFIX'*.heic '$SOURCE_DIR_CAMERA/IMG_${YEAR}${MONTH}'*.jpg '$SOURCE_DIR_CAMERA/IMG_${YEAR}${MONTH}'*.jpeg '$SOURCE_DIR_CAMERA/IMG_${YEAR}${MONTH}'*.heic '$TARGET_DIR_CAMERA/photos-${YEAR}-q${QUARTER}/' 2>/dev/null"
        fi
        
        # Handle Meta AI photos
        if [[ "$COUNT_PHOTOS_META" -gt 0 ]]; then
          adb shell "mkdir -p '$TARGET_DIR_META/photos-${YEAR}-q${QUARTER}'"
          adb shell "mv '$META_PATH/${YEAR}${MONTH}'*.jpg '$TARGET_DIR_META/photos-${YEAR}-q${QUARTER}/' 2>/dev/null"
        fi
      else
        if [[ "$COUNT_PHOTOS_CAMERA" -gt 0 ]]; then
          MISSING_DIRS["Camera/$KEY/photos-${YEAR}-q${QUARTER}"]=1
        fi
        if [[ "$COUNT_PHOTOS_META" -gt 0 ]]; then
          MISSING_DIRS["Meta AI/$KEY/photos-${YEAR}-q${QUARTER}"]=1
        fi
      fi
    fi

    # Handle videos
    if [[ "$COUNT_VIDEOS" -gt 0 ]]; then
      TOTAL_VIDEOS=$((TOTAL_VIDEOS + COUNT_VIDEOS))
      COUNTS_VIDEOS[$KEY]=$(( ${COUNTS_VIDEOS[$KEY]:-0} + COUNT_VIDEOS ))

      if [[ "$DRY_RUN" == false ]]; then
        # Handle Camera videos
        if [[ "$COUNT_VIDEOS_CAMERA" -gt 0 ]]; then
          adb shell "mkdir -p '$TARGET_DIR_CAMERA/videos-${YEAR}-q${QUARTER}'"
          adb shell "mv '$SOURCE_DIR_CAMERA/$PREFIX'*.mp4 '$SOURCE_DIR_CAMERA/$PREFIX'*.mov '$SOURCE_DIR_CAMERA/VID_${YEAR}${MONTH}'*.mp4 '$SOURCE_DIR_CAMERA/VID_${YEAR}${MONTH}'*.mov '$TARGET_DIR_CAMERA/videos-${YEAR}-q${QUARTER}/' 2>/dev/null"
        fi
        
        # Handle Meta AI videos
        if [[ "$COUNT_VIDEOS_META" -gt 0 ]]; then
          adb shell "mkdir -p '$TARGET_DIR_META/videos-${YEAR}-q${QUARTER}'"
          adb shell "mv '$META_PATH/${YEAR}${MONTH}'*.mp4 '$TARGET_DIR_META/videos-${YEAR}-q${QUARTER}/' 2>/dev/null"
        fi
      else
        if [[ "$COUNT_VIDEOS_CAMERA" -gt 0 ]]; then
          MISSING_DIRS["Camera/$KEY/videos-${YEAR}-q${QUARTER}"]=1
        fi
        if [[ "$COUNT_VIDEOS_META" -gt 0 ]]; then
          MISSING_DIRS["Meta AI/$KEY/videos-${YEAR}-q${QUARTER}"]=1
        fi
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
    echo "/sdcard/$KEY/"
  done
fi

echo "\n📁 Source folders processed:"
echo "   - /sdcard/DCIM/Camera"
echo "   - /sdcard/Download/Meta AI"
echo "\nTotal photos matched: $TOTAL_PHOTOS"
echo "Total videos matched: $TOTAL_VIDEOS"

# Show sample of what would be moved (helpful for dry-run)
if [[ "$DRY_RUN" == true ]] && [[ "$TOTAL_PHOTOS" -gt 0 || "$TOTAL_VIDEOS" -gt 0 ]]; then
  echo "\n📋 Sample files that would be moved:"
  echo "\n--- Meta AI files for 2026-02 ---"
  adb shell "ls -la '$META_PATH/202602'* 2>/dev/null | head -5"
fi

[[ "$DRY_RUN" == true ]] && echo "\n✅ Dry-run complete. No files were moved." || echo "\n✅ Files organized successfully."
