#!/bin/bash

# WiFiOn Overlay APK Cleaner - Clean WifiOn overlay APKs from out directory
# Created: $(date)
#
# ################################################################
# #                        AUTHOR INFO                          #
# ################################################################
# Script created by: Arkadiusz Kubiak
# Date: $(date '+%Y-%m-%d %H:%M:%S')
# Purpose: Remove WifiOn overlay APKs from out directory after build
# Target: Android Khadas VIM4 build - force overlay rebuild
# ################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ANDROID_ROOT="${ANDROID_ROOT:-/home/arek/workspace/android_khadas}"
ANDROID_OUT="${ANDROID_OUT:-${ANDROID_ROOT}/out/target/product/kvim4}"

print_header() {
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}           WIFION OVERLAY APK CLEANER                          ${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Clean WifiOn overlay APKs and build artifacts from out directory
clean_wifion_apks() {
    print_status "Cleaning WifiOn overlay APKs from out directory..."
    
    if [ ! -d "$ANDROID_OUT" ]; then
        print_error "Android out directory not found: $ANDROID_OUT"
        print_error "Please build first or set ANDROID_OUT environment variable"
        exit 1
    fi
    
    local removed_count=0
    
    # WifiOn overlay APKs and artifacts in out directory only
    local apk_patterns=(
        "${ANDROID_OUT}/obj/APPS/WifiOn*"
        "${ANDROID_OUT}/obj/APPS/WifiOverlay*"
        "${ANDROID_OUT}/obj/APPS/*wifion*"
        "${ANDROID_OUT}/obj/APPS/*WifiOn*"
        "${ANDROID_OUT}/system/product/overlay/WifiOn*"
        "${ANDROID_OUT}/system/product/overlay/WifiOverlay*"
        "${ANDROID_OUT}/product/overlay/WifiOn*"
        "${ANDROID_OUT}/product/overlay/WifiOverlay*"
        "${ANDROID_OUT}/system/product/app/WifiOn*"
        "${ANDROID_OUT}/system/product/app/WifiOverlay*"
        "${ANDROID_OUT}/product/app/WifiOn*"
        "${ANDROID_OUT}/product/app/WifiOverlay*"
        "${ANDROID_OUT}/obj/PACKAGING/product_intermediates/WifiOn*"
        "${ANDROID_OUT}/obj/PACKAGING/product_intermediates/WifiOverlay*"
    )
    
    for pattern in "${apk_patterns[@]}"; do
        for apk in $pattern; do
            if [ -e "$apk" ]; then
                print_warning "Removing APK/artifact: $apk"
                rm -rf "$apk"
                ((removed_count++))
            fi
        done
    done
    
    # Remove product.img to force rebuild
    if [ -f "${ANDROID_OUT}/product.img" ]; then
        print_warning "Removing: ${ANDROID_OUT}/product.img"
        rm -f "${ANDROID_OUT}/product.img"
        ((removed_count++))
    fi
    
    print_success "Removed $removed_count WifiOn APKs and artifacts"
}

# Show what will be cleaned
show_preview() {
    print_header
    echo -e "${YELLOW}PREVIEW MODE - No files will be removed${NC}"
    echo
    
    if [ ! -d "$ANDROID_OUT" ]; then
        print_error "Android out directory not found: $ANDROID_OUT"
        exit 1
    fi
    
    print_status "The following WifiOn APKs and artifacts will be cleaned:"
    echo
    
    local apk_patterns=(
        "${ANDROID_OUT}/obj/APPS/WifiOn*"
        "${ANDROID_OUT}/obj/APPS/WifiOverlay*"
        "${ANDROID_OUT}/obj/APPS/*wifion*"
        "${ANDROID_OUT}/obj/APPS/*WifiOn*"
        "${ANDROID_OUT}/system/product/overlay/WifiOn*"
        "${ANDROID_OUT}/system/product/overlay/WifiOverlay*"
        "${ANDROID_OUT}/product/overlay/WifiOn*"
        "${ANDROID_OUT}/product/overlay/WifiOverlay*"
        "${ANDROID_OUT}/product/app/WifiOn*"
        "${ANDROID_OUT}/product/app/WifiOverlay*"
    )
    
    local found_files=0
    
    for pattern in "${apk_patterns[@]}"; do
        for apk in $pattern; do
            if [ -e "$apk" ]; then
                echo "  $apk"
                ((found_files++))
            fi
        done
    done
    
    if [ -f "${ANDROID_OUT}/product.img" ]; then
        echo "  ${ANDROID_OUT}/product.img"
        ((found_files++))
    fi
    
    if [ $found_files -eq 0 ]; then
        print_status "No WifiOn APKs found - build is already clean"
    else
        print_status "Found $found_files items to clean"
    fi
    
    echo
    echo -e "${YELLOW}Run with --execute to perform the actual cleaning${NC}"
}

# Main execution
main() {
    print_header
    
    # Check if preview mode
    if [[ "$1" == "--preview" ]] || [[ "$1" == "-p" ]]; then
        show_preview
        return 0
    fi
    
    # Check if execute mode
    if [[ "$1" != "--execute" ]] && [[ "$1" != "-e" ]]; then
        print_error "This script requires --execute flag to run"
        echo "Use --preview to see what would be cleaned"
        echo "Use --execute to perform the actual cleaning"
        exit 1
    fi
    
    print_status "Starting WifiOn APK cleaning..."
    print_status "This will force WifiOn overlay to rebuild on next build"
    echo
    
    # Execute cleaning
    clean_wifion_apks
    
    # Show summary
    echo
    print_header
    echo -e "${GREEN}WIFION APK CLEANING COMPLETED${NC}"
    echo
    echo "Summary:"
    echo "• WifiOn overlay APKs and artifacts cleaned from out directory"
    echo "• product.img removed (will be rebuilt)"
    echo "• Source files left untouched"
    echo
    echo "Next steps:"
    echo "1. Run your build command (e.g., 'make productimage')"
    echo "2. WifiOn overlay will be rebuilt from scratch"
    echo "3. Flash new product.img to device"
    echo
    echo "Build commands:"
    echo "  make productimage -j\$(nproc)   # Rebuild product partition"
    echo "  make -j\$(nproc)               # Full build"
    echo
    print_header
}

# Script usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        echo "Usage: $0 [options]"
        echo
        echo "Options:"
        echo "  -p, --preview      Show what would be removed (safe mode)"
        echo "  -e, --execute      Execute the actual removal"
        echo "  -h, --help         Show this help message"
        echo
        echo "Environment variables:"
        echo "  ANDROID_ROOT       Path to Android source root"
        echo "                     Default: /home/arek/workspace/android_khadas"
        echo "  ANDROID_OUT        Path to Android build output"
        echo "                     Default: \$ANDROID_ROOT/out/target/product/kvim4"
        echo
        echo "This script will:"
        echo "• Remove WifiOn overlay APKs from out directory"
        echo "• Remove product.img from build output"
        echo "• Clean build artifacts only (no source files)"
        echo "• Force overlay rebuild on next build"
        echo
        echo "Examples:"
        echo "  $0 --preview     # Show what would be removed"
        echo "  $0 --execute     # Actually remove APKs"
        echo
        exit 0
    fi
    
    main "$@"
fi
