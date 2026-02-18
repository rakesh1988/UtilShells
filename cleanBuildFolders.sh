#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Arrays to store found folders
declare -a NODE_FOLDERS
declare -a PYTHON_VENV_FOLDERS
declare -a PYTHON_CACHE_FOLDERS
declare -a PYTHON_EGG_FOLDERS
declare -a PYTHON_BUILD_FOLDERS
declare -a ANDROID_BUILD_FOLDERS
declare -a GRADLE_FOLDERS
declare -a GRADLE_EXECUTION_HISTORY_FOLDERS
declare -a IOS_BUILD_FOLDERS
declare -a PODS_FOLDERS
declare -a DERIVEDDATA_FOLDERS

# Size tracking
declare -a FOLDER_SIZES
declare -a FOLDER_PATHS
declare -a FOLDER_TYPES
TOTAL_FOLDERS=0
TOTAL_SIZE=0

# Function to calculate directory size in bytes
get_size_bytes() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS version
        du -sk "$1" 2>/dev/null | cut -f1 | awk '{print $1 * 1024}'
    else
        # Linux version
        du -sb "$1" 2>/dev/null | cut -f1
    fi
}

# Function to format size
format_size() {
    local size=$1
    if [ $size -ge 1073741824 ]; then
        echo "$(echo "scale=2; $size/1073741824" | bc) GB"
    elif [ $size -ge 1048576 ]; then
        echo "$(echo "scale=2; $size/1048576" | bc) MB"
    elif [ $size -ge 1024 ]; then
        echo "$(echo "scale=2; $size/1024" | bc) KB"
    else
        echo "${size} B"
    fi
}

# Function to check if path is inside another build folder
is_nested_build_folder() {
    local path="$1"
    local check_path="$path"
    
    # Go up the path and check if any parent is a build folder we care about
    while [[ "$check_path" != "/" ]]; do
        check_path=$(dirname "$check_path")
        local dirname=$(basename "$check_path")
        
        # Check if parent is a build folder
        case "$dirname" in
            "node_modules"|"venv"|".venv"|"env"|".env"|"__pycache__"|"build"|"dist"|".gradle"|"Pods"|"DerivedData")
                return 0  # It's nested
                ;;
        esac
    done
    
    return 1  # Not nested
}

# Function to add folder to tracking
add_folder() {
    local path="$1"
    local type="$2"
    
    # Skip if this is inside another build folder
    if is_nested_build_folder "$path"; then
        return
    fi
    
    local size=$(get_size_bytes "$path")
    local formatted_size=$(format_size $size)
    
    FOLDER_PATHS[$TOTAL_FOLDERS]="$path"
    FOLDER_SIZES[$TOTAL_FOLDERS]=$size
    FOLDER_TYPES[$TOTAL_FOLDERS]="$type"
    TOTAL_FOLDERS=$((TOTAL_FOLDERS + 1))
    TOTAL_SIZE=$((TOTAL_SIZE + size))
    
    # Also add to category-specific arrays for summary
    case "$type" in
        "node_modules")
            NODE_FOLDERS+=("$path|$formatted_size|$size")
            ;;
        "python_venv")
            PYTHON_VENV_FOLDERS+=("$path|$formatted_size|$size")
            ;;
        "python_cache")
            PYTHON_CACHE_FOLDERS+=("$path|$formatted_size|$size")
            ;;
        "python_egg")
            PYTHON_EGG_FOLDERS+=("$path|$formatted_size|$size")
            ;;
        "python_build")
            PYTHON_BUILD_FOLDERS+=("$path|$formatted_size|$size")
            ;;
        "android_build")
            ANDROID_BUILD_FOLDERS+=("$path|$formatted_size|$size")
            ;;
        "gradle")
            GRADLE_FOLDERS+=("$path|$formatted_size|$size")
            ;;
        "gradle_execution_history")
            GRADLE_EXECUTION_HISTORY_FOLDERS+=("$path|$formatted_size|$size")
            ;;
        "ios_build")
            IOS_BUILD_FOLDERS+=("$path|$formatted_size|$size")
            ;;
        "pods")
            PODS_FOLDERS+=("$path|$formatted_size|$size")
            ;;
        "deriveddata")
            DERIVEDDATA_FOLDERS+=("$path|$formatted_size|$size")
            ;;
    esac
}

# Function to scan and collect information
scan_directories() {
    local base_dir="$1"
    
    echo -e "${GREEN}Scanning for deletable build folders in: $base_dir${NC}"
    echo "=================================================="
    echo -e "${YELLOW}This may take a while depending on the size of your directory...${NC}\n"
    
    # Find all node_modules folders (excluding nested ones)
    echo -e "${BLUE}Scanning for node_modules...${NC}"
    while IFS= read -r -d '' dir; do
        add_folder "$dir" "node_modules"
    done < <(find "$base_dir" -type d -name "node_modules" -not -path "*/\.*" -print0 2>/dev/null)
    
    # Find Python virtual environments
    echo -e "${YELLOW}Scanning for Python virtual environments...${NC}"
    while IFS= read -r -d '' dir; do
        add_folder "$dir" "python_venv"
    done < <(find "$base_dir" -type d \( -name "venv" -o -name ".venv" -o -name "env" -o -name ".env" -o -name "virtualenv" \) -not -path "*/\.*" -print0 2>/dev/null)
    
    # Find Python cache directories
    echo -e "${YELLOW}Scanning for Python cache...${NC}"
    while IFS= read -r -d '' dir; do
        add_folder "$dir" "python_cache"
    done < <(find "$base_dir" -type d -name "__pycache__" -not -path "*/\.*" -print0 2>/dev/null)
    
    # Find Python egg info
    echo -e "${YELLOW}Scanning for Python egg info...${NC}"
    while IFS= read -r -d '' dir; do
        add_folder "$dir" "python_egg"
    done < <(find "$base_dir" -type d -name "*.egg-info" -not -path "*/\.*" -print0 2>/dev/null)
    
    # Find Python build/dist folders
    echo -e "${YELLOW}Scanning for Python build/dist...${NC}"
    while IFS= read -r -d '' dir; do
        parent_dir=$(dirname "$dir")
        if [ -f "$parent_dir/setup.py" ] || [ -f "$parent_dir/requirements.txt" ] || [ -f "$parent_dir/pyproject.toml" ]; then
            add_folder "$dir" "python_build"
        fi
    done < <(find "$base_dir" -type d \( -name "build" -o -name "dist" \) -not -path "*/\.*" -print0 2>/dev/null)
    
    # Find Android build folders
    echo -e "${GREEN}Scanning for Android build folders...${NC}"
    while IFS= read -r -d '' dir; do
        parent_dir=$(dirname "$dir")
        if [ -f "$parent_dir/settings.gradle" ] || [ -f "$parent_dir/build.gradle" ] || [ -f "$parent_dir/gradle.properties" ]; then
            add_folder "$dir" "android_build"
        fi
    done < <(find "$base_dir" -type d -name "build" -not -path "*/\.*" -print0 2>/dev/null)
    
    # Find Gradle cache
    echo -e "${GREEN}Scanning for Gradle cache...${NC}"
    while IFS= read -r -d '' dir; do
        add_folder "$dir" "gradle"
    done < <(find "$base_dir" -type d -name ".gradle" -not -path "*/\.*" -print0 2>/dev/null)
    
    # Find Gradle execution history folders
    echo -e "${GREEN}Scanning for Gradle execution history...${NC}"
    while IFS= read -r -d '' dir; do
        # Only add if it's an executionHistory folder inside a Gradle cache
        if [[ "$dir" == *"/caches/"*"/executionHistory" ]]; then
            add_folder "$dir" "gradle_execution_history"
        fi
    done < <(find "$base_dir" -type d -path "*/caches/*/executionHistory" -not -path "*/\.*" -print0 2>/dev/null)
    
    # Find iOS/macOS build folders
    echo -e "${PURPLE}Scanning for iOS/macOS build folders...${NC}"
    while IFS= read -r -d '' dir; do
        if find "$(dirname "$dir")" -maxdepth 2 -name "*.xcodeproj" -o -name "*.xcworkspace" 2>/dev/null | grep -q .; then
            add_folder "$dir" "ios_build"
        fi
    done < <(find "$base_dir" -type d -name "build" -not -path "*/\.*" -print0 2>/dev/null)
    
    # Find CocoaPods
    echo -e "${PURPLE}Scanning for CocoaPods...${NC}"
    while IFS= read -r -d '' dir; do
        add_folder "$dir" "pods"
    done < <(find "$base_dir" -type d -name "Pods" -not -path "*/\.*" -print0 2>/dev/null)
    
    # Find DerivedData
    echo -e "${PURPLE}Scanning for Xcode DerivedData...${NC}"
    while IFS= read -r -d '' dir; do
        add_folder "$dir" "deriveddata"
    done < <(find "$base_dir" -type d -name "DerivedData" -not -path "*/\.*" -print0 2>/dev/null)
}

# Function to print category summary
print_category() {
    local title="$1"
    local icon="$2"
    local color="$3"
    shift 3
    local -a items=("$@")
    
    if [ ${#items[@]} -gt 0 ]; then
        echo -e "\n${color}${icon} ${title} (${#items[@]} found):${NC}"
        local category_size=0
        local count=0
        for item in "${items[@]}"; do
            IFS='|' read -r path size bytes <<< "$item"
            count=$((count + 1))
            # Show only first 5 items if there are many
            if [ $count -le 5 ]; then
                echo -e "  ${color}•${NC} $path ${YELLOW}($size)${NC}"
            elif [ $count -eq 6 ]; then
                echo -e "  ${color}└─ ... and $((${#items[@]} - 5)) more${NC}"
            fi
            category_size=$((category_size + bytes))
        done
        echo -e "  ${color}└─ Total: $(format_size $category_size)${NC}"
    fi
}

# Function to show summary
show_summary() {
    echo -e "\n${CYAN}════════════════════════════════════════════${NC}"
    echo -e "${CYAN}           SCAN SUMMARY${NC}"
    echo -e "${CYAN}════════════════════════════════════════════${NC}"
    
    # Print by category
    print_category "Node.js node_modules" "📦" "$BLUE" "${NODE_FOLDERS[@]}"
    print_category "Python Virtual Environments" "🐍" "$YELLOW" "${PYTHON_VENV_FOLDERS[@]}"
    print_category "Python Cache" "🐍" "$YELLOW" "${PYTHON_CACHE_FOLDERS[@]}"
    print_category "Python Egg Info" "🐍" "$YELLOW" "${PYTHON_EGG_FOLDERS[@]}"
    print_category "Python Build/Dist" "🐍" "$YELLOW" "${PYTHON_BUILD_FOLDERS[@]}"
    print_category "Android Build" "🤖" "$GREEN" "${ANDROID_BUILD_FOLDERS[@]}"
    print_category "Gradle Cache" "🤖" "$GREEN" "${GRADLE_FOLDERS[@]}"
    print_category "Gradle Execution History" "📜" "$GREEN" "${GRADLE_EXECUTION_HISTORY_FOLDERS[@]}"
    print_category "iOS/macOS Build" "🍎" "$PURPLE" "${IOS_BUILD_FOLDERS[@]}"
    print_category "CocoaPods" "🍎" "$PURPLE" "${PODS_FOLDERS[@]}"
    print_category "Xcode DerivedData" "🍎" "$PURPLE" "${DERIVEDDATA_FOLDERS[@]}"
    
    # Grand total
    echo -e "\n${CYAN}════════════════════════════════════════════${NC}"
    echo -e "${GREEN}TOTAL SUMMARY:${NC}"
    echo -e "  Total folders found: ${YELLOW}$TOTAL_FOLDERS${NC}"
    echo -e "  Total space that can be freed: ${YELLOW}$(format_size $TOTAL_SIZE)${NC}"
    
    if [ $TOTAL_FOLDERS -eq 0 ]; then
        echo -e "\n${GREEN}No deletable folders found! Your directory is clean.${NC}"
        exit 0
    fi
}

# Function to perform per-folder deletion with confirmation
perform_deletion() {
    echo -e "\n${RED}⚠  Starting per-folder deletion process${NC}"
    echo -e "${YELLOW}You will be asked to confirm each deletion individually.${NC}"
    echo -e "${YELLOW}Type 'y' for yes, 'n' for no, 'a' for yes to all, or 'q' to quit.${NC}\n"
    
    local deleted_size=0
    local deleted_count=0
    local skipped_count=0
    local yes_to_all=false
    
    for ((i=0; i<$TOTAL_FOLDERS; i++)); do
        path="${FOLDER_PATHS[$i]}"
        type="${FOLDER_TYPES[$i]}"
        size="${FOLDER_SIZES[$i]}"
        formatted_size=$(format_size $size)
        
        # Show folder details
        echo -e "\n${CYAN}[$((i+1))/$TOTAL_FOLDERS]${NC} Found: $path"
        echo -e "  Type: ${BLUE}$type${NC}"
        echo -e "  Size: ${YELLOW}$formatted_size${NC}"
        
        if [ "$yes_to_all" = true ]; then
            echo -e "  ${GREEN}✓ Auto-deleting (yes to all)${NC}"
            choice="y"
        else
            echo -e "${RED}Delete this folder? (y/n/a/q)${NC}"
            read -r choice
        fi
        
        case $choice in
            [Yy])
                echo -e "  Deleting..."
                rm -rf "$path"
                if [ $? -eq 0 ]; then
                    echo -e "  ${GREEN}✓ Deleted successfully${NC}"
                    deleted_size=$((deleted_size + size))
                    deleted_count=$((deleted_count + 1))
                else
                    echo -e "  ${RED}✗ Failed to delete${NC}"
                    skipped_count=$((skipped_count + 1))
                fi
                ;;
            [Aa])
                echo -e "  ${GREEN}✓ Yes to all - deleting this and all remaining folders${NC}"
                yes_to_all=true
                echo -e "  Deleting..."
                rm -rf "$path"
                if [ $? -eq 0 ]; then
                    echo -e "  ${GREEN}✓ Deleted successfully${NC}"
                    deleted_size=$((deleted_size + size))
                    deleted_count=$((deleted_count + 1))
                else
                    echo -e "  ${RED}✗ Failed to delete${NC}"
                    skipped_count=$((skipped_count + 1))
                fi
                ;;
            [Nn])
                echo -e "  ${BLUE}✗ Skipped${NC}"
                skipped_count=$((skipped_count + 1))
                ;;
            [Qq])
                echo -e "\n${BLUE}Quitting deletion process.${NC}"
                break
                ;;
            *)
                echo -e "  ${YELLOW}Invalid input. Skipping...${NC}"
                skipped_count=$((skipped_count + 1))
                ;;
        esac
    done
    
    # Show final summary
    echo -e "\n${GREEN}════════════════════════════════════════════${NC}"
    echo -e "${GREEN}DELETION COMPLETE${NC}"
    echo -e "  Folders deleted: ${YELLOW}$deleted_count${NC}"
    echo -e "  Folders skipped: ${YELLOW}$skipped_count${NC}"
    echo -e "  Total space freed: ${YELLOW}$(format_size $deleted_size)${NC}"
    
    if [ $deleted_count -gt 0 ]; then
        echo -e "\n${GREEN}✓ Great! You've freed up $(format_size $deleted_size) of space.${NC}"
    fi
}

# Main execution
main() {
    if [ $# -eq 0 ]; then
        echo -e "${RED}Usage: $0 <directory>${NC}"
        echo -e "Example: $0 ~/Projects"
        exit 1
    fi
    
    local target_dir="$1"
    
    # Check if directory exists
    if [ ! -d "$target_dir" ]; then
        echo -e "${RED}Error: Directory '$target_dir' does not exist${NC}"
        exit 1
    fi
    
    # Scan directories
    scan_directories "$target_dir"
    
    # Show summary
    show_summary
    
    # Ask if user wants to proceed with per-folder deletion
    if [ $TOTAL_FOLDERS -gt 0 ]; then
        echo -e "\n${CYAN}Do you want to proceed with per-folder deletion? (yes/no)${NC}"
        read -r delete_answer
        
        if [[ "$delete_answer" =~ ^[Yy]es$ ]]; then
            perform_deletion
        else
            echo -e "${BLUE}No folders were deleted.${NC}"
        fi
    fi
}

# Run main function
main "$@"