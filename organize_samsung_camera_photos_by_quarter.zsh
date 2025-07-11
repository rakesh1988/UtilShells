#!/bin/zsh

# Enable dry-run mode by passing --dry-run
DRY_RUN=false
[[ "$1" == "--dry-run" ]] && DRY_RUN=true && echo "🔍 Running in dry-run mode..."

SOURCE_DIR="/sdcard/DCIM/Camera"
typeset -A COUNTS
typeset -A MISSING_DIRS
TOTAL_FILES=0

for YEAR in {2024..2025}; do
  for MONTH in {01..12}; do
    MONTH_INT=$((10#$MONTH))
    QUARTER=$(( (MONTH_INT - 1) / 3 + 1 ))
    PREFIX="${YEAR}${MONTH}"
    TARGET_DIR="$SOURCE_DIR/$YEAR/q$QUARTER"
    KEY="${YEAR}/q${QUARTER}"

    COUNT=$(adb shell "ls '$SOURCE_DIR/$PREFIX'* 2>/dev/null | wc -l" | tr -d '\r')
    if [[ "$COUNT" -gt 0 ]]; then
      TOTAL_FILES=$((TOTAL_FILES + COUNT))
      COUNTS[$KEY]=$(( ${COUNTS[$KEY]:-0} + COUNT ))

      EXISTS=$(adb shell "[ -d '$TARGET_DIR' ] && echo yes || echo no" | tr -d '\r')
      [[ "$EXISTS" == "no" ]] && MISSING_DIRS[$KEY]=1

      if [[ "$DRY_RUN" == false ]]; then
        adb shell "mkdir -p '$TARGET_DIR'"
        adb shell "mv '$SOURCE_DIR/$PREFIX'* '$TARGET_DIR/'"
      fi
    fi
  done
done

echo "\n📊 Summary:"
echo "-----------"
for KEY in ${(k)COUNTS}; do
  echo "$KEY → ${COUNTS[$KEY]} files"
done

if (( ${#MISSING_DIRS[@]} > 0 )); then
  echo "\n⚠️ Missing target directories (would be created):"
  for KEY in ${(k)MISSING_DIRS}; do
    echo "$SOURCE_DIR/$KEY/"
  done
fi

echo "\nTotal files matched: $TOTAL_FILES"
[[ "$DRY_RUN" == true ]] && echo "✅ Dry-run complete. No files were moved." || echo "✅ Files organized successfully."
