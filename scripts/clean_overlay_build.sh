#!/bin/bash

# Clean Overlay Build Script for AOSP Car SDK
# Purpose: Force rebuild of overlays and system images after overlay modifications
# Author: Arkadiusz Kubiak
# Usage: ./clean_overlay_build.sh [target_name]
# Example: ./clean_overlay_build.sh sdk_car_x86_64

set -euo pipefail

# ANSI Color codes (simplified)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default target
DEFAULT_TARGET="sdk_car_x86_64"
TARGET="${1:-$DEFAULT_TARGET}"

# Check if we're in AOSP root directory
if [[ ! -f "build/envsetup.sh" ]]; then
    echo -e "${RED}Error: Not in AOSP root directory${NC}"
    echo "Please run this script from the AOSP root directory"
    exit 1
fi

# Set ANDROID_PRODUCT_OUT if not set
if [[ -z "${ANDROID_PRODUCT_OUT:-}" ]]; then
    if [[ -d "out/target/product/${TARGET}" ]]; then
        export ANDROID_PRODUCT_OUT="out/target/product/${TARGET}"
    else
        echo -e "${RED}Error: Target directory out/target/product/${TARGET} not found${NC}"
        echo "Available targets:"
        find out/target/product -maxdepth 1 -type d -name "*car*" 2>/dev/null | sed 's|.*/||' | sort
        exit 1
    fi
fi

echo -e "${BLUE}=== AOSP Overlay Clean Build Script ===${NC}"
echo -e "${YELLOW}Target: ${TARGET}${NC}"
echo -e "${YELLOW}Product out: ${ANDROID_PRODUCT_OUT}${NC}"
echo

# Function to safely remove files/directories
safe_remove() {
    local path="$1"
    local description="$2"
    
    if [[ -e "$path" ]]; then
        echo -e "${YELLOW}Removing: ${description}${NC}"
        rm -rf "$path"
        echo -e "${GREEN}✓ Removed: $path${NC}"
    else
        echo -e "${BLUE}✓ Already clean: $path${NC}"
    fi
}

# Function to clean overlay-specific build artifacts
clean_overlay_artifacts() {
    echo -e "${BLUE}--- Cleaning Overlay Build Artifacts ---${NC}"
    
    # Clean overlay APKs from product output
    safe_remove "${ANDROID_PRODUCT_OUT}/system/overlay" "System overlay directory"
    safe_remove "${ANDROID_PRODUCT_OUT}/vendor/overlay" "Vendor overlay directory"
    safe_remove "${ANDROID_PRODUCT_OUT}/product/overlay" "Product overlay directory"
    safe_remove "${ANDROID_PRODUCT_OUT}/system_ext/overlay" "System extension overlay directory"
    safe_remove "${ANDROID_PRODUCT_OUT}/odm/overlay" "ODM overlay directory"
    safe_remove "${ANDROID_PRODUCT_OUT}/oem/overlay" "OEM overlay directory"
    
    # Clean overlay build intermediates
    safe_remove "out/soong/.intermediates/device/generic/car" "Car overlay intermediates"
    safe_remove "out/soong/.intermediates/packages/services/Car" "Car services overlay intermediates"
    safe_remove "out/soong/.intermediates/device/generic/goldfish" "Goldfish overlay intermediates"
    
    # Clean specific overlay APK intermediates
    find out/soong/.intermediates -name "*SettingsProvider*overlay*" -type d 2>/dev/null | while read -r dir; do
        safe_remove "$dir" "SettingsProvider overlay intermediate: $(basename "$dir")"
    done
    
    find out/soong/.intermediates -name "*RRO*" -type d 2>/dev/null | while read -r dir; do
        safe_remove "$dir" "RRO intermediate: $(basename "$dir")"
    done
}

# Function to clean system images that include overlays
clean_system_images() {
    echo -e "${BLUE}--- Cleaning System Images ---${NC}"
    
    # System images that contain overlays
    safe_remove "${ANDROID_PRODUCT_OUT}/system.img" "System image"
    safe_remove "${ANDROID_PRODUCT_OUT}/vendor.img" "Vendor image"
    safe_remove "${ANDROID_PRODUCT_OUT}/product.img" "Product image"
    safe_remove "${ANDROID_PRODUCT_OUT}/system_ext.img" "System extension image"
    safe_remove "${ANDROID_PRODUCT_OUT}/super.img" "Super image"
    safe_remove "${ANDROID_PRODUCT_OUT}/vbmeta.img" "VBMeta image"
    
    # Image build intermediates
    safe_remove "${ANDROID_PRODUCT_OUT}/obj/PACKAGING/systemimage_intermediates" "System image intermediates"
    safe_remove "${ANDROID_PRODUCT_OUT}/obj/PACKAGING/vendorimage_intermediates" "Vendor image intermediates"
    safe_remove "${ANDROID_PRODUCT_OUT}/obj/PACKAGING/productimage_intermediates" "Product image intermediates"
    safe_remove "${ANDROID_PRODUCT_OUT}/obj/PACKAGING/system_extimage_intermediates" "System extension image intermediates"
}

# Function to clean package installation artifacts
clean_package_artifacts() {
    echo -e "${BLUE}--- Cleaning Package Installation Artifacts ---${NC}"
    
    # Clean installed package lists
    safe_remove "${ANDROID_PRODUCT_OUT}/installed-files.txt" "Installed files list"
    safe_remove "${ANDROID_PRODUCT_OUT}/installed-files.json" "Installed files JSON"
    safe_remove "${ANDROID_PRODUCT_OUT}/installed-files-vendor.txt" "Installed vendor files list"
    safe_remove "${ANDROID_PRODUCT_OUT}/installed-files-product.txt" "Installed product files list"
    
    # Clean AAPT2 cache which may cache overlay resources
    safe_remove "out/soong/.intermediates/build/soong/cmd/merge_zips" "AAPT2 merge cache"
    
    # Clean overlay-related stamps
    find "${ANDROID_PRODUCT_OUT}" -name "*overlay*.stamp" 2>/dev/null | while read -r stamp; do
        safe_remove "$stamp" "Overlay stamp: $(basename "$stamp")"
    done
}

# Function to clean specific Car SDK overlay artifacts
clean_car_sdk_overlays() {
    echo -e "${BLUE}--- Cleaning Car SDK Specific Overlays ---${NC}"
    
    # Car-specific overlay APKs
    local car_overlays=(
        "CarSettingsProviderConfigRRO"
        "SettingsProvider__${TARGET}__auto_generated_rro_vendor"
        "SettingsProvider__${TARGET}__auto_generated_rro_product" 
        "CarSettings__${TARGET}__auto_generated_rro_product"
    )
    
    for overlay in "${car_overlays[@]}"; do
        # Clean from product output
        safe_remove "${ANDROID_PRODUCT_OUT}/product/overlay/${overlay}.apk" "Car overlay: ${overlay}"
        safe_remove "${ANDROID_PRODUCT_OUT}/vendor/overlay/${overlay}.apk" "Car overlay: ${overlay}"
        
        # Clean build intermediates
        find out/soong/.intermediates -name "*${overlay}*" -type d 2>/dev/null | while read -r dir; do
            safe_remove "$dir" "Car overlay intermediate: $(basename "$dir")"
        done
    done
}

# Function to clean resource compilation cache
clean_resource_cache() {
    echo -e "${BLUE}--- Cleaning Resource Compilation Cache ---${NC}"
    
    # Clean AAPT2 compiled resources
    safe_remove "out/soong/.intermediates/frameworks/base/packages/SettingsProvider" "SettingsProvider compiled resources"
    
    # Clean resource intermediate files
    find out/soong/.intermediates -name "*.arsc" 2>/dev/null | while read -r arsc; do
        safe_remove "$arsc" "Compiled resource: $(basename "$arsc")"
    done
    
    # Clean R.java files that may reference overlay resources
    find out/soong/.intermediates -name "R.java" -path "*/SettingsProvider/*" 2>/dev/null | while read -r rjava; do
        safe_remove "$rjava" "R.java file: $rjava"
    done
}

# Main execution
main() {
    echo -e "${YELLOW}Starting overlay clean for target: ${TARGET}${NC}"
    echo -e "${YELLOW}This will force rebuild of overlays and system images${NC}"
    echo
    
    # Ask for confirmation
    read -p "Do you want to continue? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Clean cancelled${NC}"
        exit 0
    fi
    
    # Execute cleaning functions
    clean_overlay_artifacts
    echo
    clean_car_sdk_overlays  
    echo
    clean_system_images
    echo
    clean_package_artifacts
    echo
    clean_resource_cache
    echo
    
    echo -e "${GREEN}=== Clean Complete ===${NC}"
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Source build environment: . build/envsetup.sh"
    echo "2. Set lunch target: lunch ${TARGET}-trunk_staging-userdebug"
    echo "3. Build overlays: make -j\$(nproc) [specific_overlay_target]"
    echo "4. Or build full system: make -j\$(nproc)"
    echo
    echo -e "${BLUE}Tip: After rebuild, verify overlays with:${NC}"
    echo "adb shell cmd overlay list | grep settings"
    echo
}

# Help function
show_help() {
    cat << EOF
Clean Overlay Build Script for AOSP Car SDK

USAGE:
    $0 [TARGET_NAME]

ARGUMENTS:
    TARGET_NAME    Build target name (default: sdk_car_x86_64)

EXAMPLES:
    $0                           # Clean for default sdk_car_x86_64
    $0 sdk_car_arm64            # Clean for arm64 car target
    $0 aosp_car_x86_64          # Clean for AOSP car target

DESCRIPTION:
    This script cleans overlay-related build artifacts to force rebuild
    of Runtime Resource Overlays (RROs) and system images. Use this when:
    
    - Overlay XML files have been modified
    - Overlay priorities need to be recalculated  
    - System images need to include updated overlays
    - Debugging overlay application issues

CLEANED ARTIFACTS:
    - Overlay APK files in all partitions
    - Overlay build intermediates
    - System/vendor/product images
    - Resource compilation cache
    - Package installation artifacts
    - Car SDK specific overlays

EOF
}

# Check for help flag
if [[ "${1:-}" =~ ^(-h|--help)$ ]]; then
    show_help
    exit 0
fi

# Execute main function
main "$@"
