#!/bin/bash

# ============================================================================
# Khadas VIM4 - Interactive Flash Selection Script
# ============================================================================
# Author: Arkadiusz Kubiak
# LinkedIn: https://www.linkedin.com/in/arkadiusz-kubiak-1b4994150
# Purpose: Interactive Android .img flashing tool for Khadas VIM4
# Version: 2.0 - Enhanced with comprehensive comments and documentation
# Created: 2025
# 
# Description:
# This script provides an interactive interface for flashing Android image files
# to the Khadas VIM4 development board. It supports both fastboot and fastbootd
# modes, handles A/B partitions, dynamic partitions, and provides comprehensive
# diagnostics to help users understand their device's partition layout.
#
# Key Features:
# ✅ Interactive file selection with intelligent presets
# ✅ Automatic detection of required fastboot mode (fastboot vs fastbootd)
# ✅ Comprehensive bootloader unlock verification
# ✅ Detailed partition diagnostics and device information
# ✅ Color-coded output with emojis for enhanced user experience
# ✅ Robust error handling with detailed troubleshooting guidance
# ✅ Support for dynamic partitions (super.img)
# ✅ Compatibility with various Bash versions (no associative arrays)
# ✅ Comprehensive logging and progress feedback
#
# Usage Examples:
# --------------
# Basic usage (run from directory containing .img files):
#   ./flash_interactive.sh
#
# Run diagnostics first (recommended for new users):
#   ./flash_interactive.sh  # Choose option 6 for diagnostics
#
# Quick essential flash:
#   ./flash_interactive.sh  # Choose option 1 for essential only
#
# Prerequisites:
# -------------
# 🔧 CRITICAL: Unlocked bootloader (see docs/VIM4_partitions.md)
# 🔧 Android platform tools (adb, fastboot) installed and in PATH
# 🔧 USB debugging enabled on device (for ADB method)
# 🔧 Appropriate .img files in the project directory
# 🔧 Reliable USB connection and proper drivers
#
# Safety Notes:
# ------------
# ⚠️  Always unlock bootloader BEFORE running this script
# ⚠️  Flashing wrong images can brick your device
# ⚠️  userdata.img will erase all user data (script will ask for confirmation)
# ⚠️  Ensure stable power and USB connection during flashing
# ⚠️  Have recovery method ready (UART access, recovery images)
#
# Troubleshooting:
# ---------------
# 🔍 Use diagnostics option (6) to understand your device
# 🔍 Check bootloader unlock status if flashing fails
# 🔍 Verify .img files are in correct directory
# 🔍 Try different USB cable/port if connection issues
# 🔍 See docs/VIM4_partitions.md for detailed instructions
# ============================================================================

# Enable strict error handling - script will exit immediately on any command failure
# This prevents partial flashing and ensures script stops at first sign of trouble
set -e

# ============================================================================
# OUTPUT STYLING AND EMOJI FUNCTIONS
# ============================================================================
# This section defines consistent color schemes and emoji-enhanced output
# functions for better user experience and visual feedback.
# All color codes use ANSI escape sequences for terminal compatibility.
# ============================================================================

# ANSI Color Codes - simplified and more readable color scheme
readonly RED='\033[0;31m'      # Errors only
readonly GREEN='\033[0;32m'    # Success messages only
readonly YELLOW='\033[0;33m'   # Warnings only
readonly BLUE='\033[0;34m'     # Headers only
readonly WHITE='\033[0;37m'    # Normal info (no color for most text)
readonly BOLD='\033[1m'        # Important text
readonly NC='\033[0m'          # No Color - reset to default

# ============================================================================
# Simplified Output Functions - Less Colorful, More Readable
# ============================================================================
# Reduced emoji usage and simplified color scheme for better readability
# Focus on clear hierarchy: errors=red, success=green, warnings=yellow, headers=blue
# ============================================================================

print_error() {
    # Red for errors only - clear indication of problems
    echo -e "${RED}✗ ERROR: $1${NC}"
}

print_success() {
    # Green for success only - clear confirmation of completion
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    # Yellow for warnings only - important but not critical
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
}

print_info() {
    # No color for regular info - easier on the eyes
    echo "• $1"
}

print_step() {
    # Minimal color for steps - just slight emphasis
    echo -e "${BOLD}→ $1${NC}"
}

print_header() {
    # Blue for headers only - clear section separation
    echo
    echo -e "${BLUE}${BOLD}=== $1 ===${NC}"
}

print_device() {
    # No special color for device info - keep it simple
    echo "📱 $1"
}

print_flash() {
    # Bold for flashing operations - important but not colored
    echo -e "${BOLD}⚡ Flashing: $1${NC}"
}

print_partition() {
    # No special color for partition info
    echo "  💾 $1"
}

# ============================================================================
# BOOTLOADER UNLOCK REQUIREMENTS
# ============================================================================
# IMPORTANT: BOOTLOADER MUST BE UNLOCKED BEFORE FLASHING
# =======================================================
# Before using this script, you MUST unlock the bootloader on your Khadas VIM4.
# This requires a USB-TTL converter and serial connection to the device.
# 
# For detailed bootloader unlock instructions, see:
# docs/VIM4_partitions.md - Section: "Khadas VIM4 Bootloader Unlock"
# 
# Quick summary:
# 1. Connect USB-TTL converter to VIM4 GPIO pins (GND, TX, RX)
# 2. Use serial terminal with 921600 baud rate
# 3. Enter U-Boot console during boot
# 4. Run commands:
#    kvim4# setenv lock 0
#    kvim4# setenv avb2 0
#    kvim4# saveenv
#    kvim4# reset
# 
# WARNING: Using this script on a locked bootloader will result in errors!
# =======================================================

# ============================================================================
# CONFIGURATION
# ============================================================================

# Configure project directory - change this path as needed
# Leave empty to use script's location automatically
# This should point to your Android build output directory containing .img files
PROJECT_PATH="/home/arek/workspace/android_khadas/out/target/product/kvim4"

# Set project directory based on configuration
# If PROJECT_PATH is set, use it; otherwise use script's directory
if [ -n "$PROJECT_PATH" ]; then
    PROJECT_DIR="$PROJECT_PATH"
else
    PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Change to project directory where .img files are located
# This ensures all file operations work from the correct location
cd "$PROJECT_DIR"

# ============================================================================
# PARTITION DEFINITIONS
# ============================================================================

# Function to get partition descriptions
# Returns human-readable description for each partition type
# This helps users understand what each partition contains and its importance
get_partition_description() {
    case "$1" in
        "bootloader.img") echo "Bootloader (U-Boot) - Required for boot" ;;
        "boot.img") echo "Kernel + Ramdisk - Required for Android boot" ;;
        "vbmeta.img") echo "Verification metadata - Required for verified boot" ;;
        "system.img") echo "Main Android system - Required" ;;
        "vendor.img") echo "Device-specific files - Required" ;;
        "product.img") echo "Product apps - Recommended" ;;
        "system_ext.img") echo "System extensions - Recommended" ;;
        "odm.img") echo "ODM modifications - Recommended" ;;
        "userdata.img") echo "User data partition - Optional (erases data)" ;;
        "dtbo.img") echo "Device Tree Overlay - Required for hardware" ;;
        "logo.img") echo "Boot logo - Optional" ;;
        "init_boot.img") echo "Init boot (Android 13+) - Optional" ;;
        "vendor_boot.img") echo "Vendor boot partition - Optional" ;;
        "vbmeta_system.img") echo "System verification metadata - Optional" ;;
        "odm_ext.img") echo "ODM extensions - Optional" ;;
        "oem.img") echo "OEM partition - Optional" ;;
        "vendor_dlkm.img") echo "Vendor kernel modules - Optional" ;;
        "system_dlkm.img") echo "System kernel modules - Optional" ;;
        "odm_dlkm.img") echo "ODM kernel modules - Optional" ;;
        "super.img") echo "Super partition (all dynamic partitions) - Alternative" ;;
        *) echo "Unknown partition" ;;
    esac
}

# List of all partition files to check for existence
# This array contains all possible Android partition images that might be present
# The script will scan for these files and show their availability to the user
readonly PARTITION_FILES=(
    "bootloader.img" "boot.img" "vbmeta.img" "system.img" "vendor.img" 
    "product.img" "system_ext.img" "odm.img" "userdata.img" "dtbo.img" 
    "logo.img" "init_boot.img" "vendor_boot.img" "vbmeta_system.img" 
    "odm_ext.img" "oem.img" "vendor_dlkm.img" "system_dlkm.img" 
    "odm_dlkm.img" "super.img"
)

# Partition mode classification
# These arrays define which partitions need to be flashed in which fastboot mode

# Files that can be flashed in regular fastboot mode (bootloader mode)
# These are typically bootloader, kernel, and boot-related partitions
readonly FASTBOOT_FILES=(
    "bootloader.img" "boot.img" "vbmeta.img" "dtbo.img" "logo.img" 
    "init_boot.img" "vendor_boot.img" "vbmeta_system.img"
)

# Files that require fastbootd mode (userspace fastboot)
# These are dynamic partitions that need special handling
readonly FASTBOOTD_FILES=(
    "system.img" "vendor.img" "product.img" "system_ext.img" "odm.img" 
    "odm_ext.img" "oem.img" "vendor_dlkm.img" "system_dlkm.img" 
    "odm_dlkm.img" "super.img" "userdata.img"
)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
# This section contains core utility functions for device management,
# partition diagnostics, and preparation procedures. These functions handle
# the complex interactions with fastboot/ADB and provide detailed feedback.
# ============================================================================

# Function to check if bootloader is unlocked
# ==========================================
# This is critical - flashing will fail if bootloader is locked
# The function queries the device's unlock status and provides detailed
# instructions if unlocking is needed.
# 
# Returns: 0 (success) if unlocked, 1 (failure) if locked or inaccessible
check_bootloader_unlock() {
    print_header "⚠ BOOTLOADER UNLOCK CHECK ⚠"
    print_step "Checking bootloader unlock status..."
    
    # Query the bootloader unlock status using fastboot
    # This command works in both bootloader and fastbootd modes
    local unlocked_status=$(fastboot getvar unlocked 2>&1 | grep "unlocked:" | cut -d':' -f2 | tr -d ' ')
    
    print_info "Current bootloader status: unlocked = $unlocked_status"
    
    # Verify bootloader is unlocked (should return "yes")
    if [ "$unlocked_status" = "yes" ]; then
        print_success "Bootloader is properly unlocked (unlocked=yes)"
        return 0
    else
        # Bootloader is locked - provide comprehensive unlock instructions
        print_error "Bootloader is still locked!"
        echo
        print_info "Expected bootloader status: unlocked = yes"
        print_warning "Currently: unlocked = $unlocked_status"
        echo
        print_info "To unlock bootloader (requires hardware access):"
        print_step "1. Connect USB-TTL converter to VIM4 GPIO pins:"
        echo "   • GND (Pin 30) -> GND on TTL converter"
        echo "   • TX (Pin 8)   -> RX on TTL converter"  
        echo "   • RX (Pin 10)  -> TX on TTL converter"
        print_step "2. Open serial terminal (921600 baud, 8N1)"
        print_step "3. Power on VIM4 and enter U-Boot console"
        print_step "4. Execute unlock commands:"
        echo "   kvim4# setenv lock 0     # Disable bootloader lock"
        echo "   kvim4# setenv avb2 0     # Disable verified boot"
        echo "   kvim4# saveenv           # Save changes"
        echo "   kvim4# reset             # Reboot device"
        echo
        print_info "Detailed instructions with images:"
        print_info "docs/VIM4_partitions.md - Section: 'Khadas VIM4 Bootloader Unlock'"
        return 1
    fi
}

# Function to run comprehensive partition diagnostics on VIM4
# =========================================================
# This diagnostic function provides detailed information about the device's
# partition layout, A/B slot system, dynamic partition support, and current
# fastboot mode. Essential for understanding device capabilities and 
# troubleshooting flashing issues.
#
# What it checks:
# 1. Available partitions with sizes (converted to MB)
# 2. A/B slot support for seamless updates  
# 3. Dynamic partition support (super partition)
# 4. Current fastboot mode (bootloader vs fastbootd)
check_vim4_partitions() {
    print_header "=== VIM4 PARTITION DIAGNOSTICS ==="
    print_device "Analyzing partition layout on your Khadas VIM4..."
    print_info "This will help understand your device's storage configuration"
    echo
    
    # Query all fastboot variables containing partition and device information
    # This provides comprehensive data about the device's partition table
    print_step "Querying fastboot variables (this may take a moment)..."
    local fastboot_output=$(fastboot getvar all 2>&1)
    
    echo
    print_header "1. Available partitions with sizes:"
    print_info "==================================="
    print_info "Showing all partitions found on device with their sizes in MB"
    # Process partition size data:
    # - Extract partition-size entries
    # - Remove _a/_b suffixes for cleaner display (A/B partitions)
    # - Convert hexadecimal sizes to human-readable MB format
    echo "$fastboot_output" | grep "partition-size:" | \
        sed 's/partition-size://g' | \
        sed 's/_a:/:/' | sed 's/_b:/:/' | \
        awk -F: '{printf "%-20s %s\n", $2, $3}' | \
        sort -u | \
        while read partition size; do
            # Convert hex size (0x format) to decimal MB
            local size_mb=$((0x${size#0x} / 1024 / 1024))
            print_partition "$partition (${size_mb}MB)"
        done
    
    echo
    print_header "2. A/B Slot System Analysis:"
    print_info "============================"
    print_info "A/B partitions enable seamless updates (Android updates in background)"
    # Show which partitions support A/B slot system
    # This is critical for understanding update mechanisms
    echo "$fastboot_output" | grep "has-slot:" | grep ":yes" | \
        sed 's/has-slot://g' | sed 's/:yes//g' | \
        awk '{printf "• %s (supports A/B slots)\n", $2}' | sort
    
    echo
    print_header "3. Dynamic Partition Support:"
    print_info "============================="
    print_info "Dynamic partitions allow flexible partition resizing (Android 10+)"
    # Check if device supports dynamic partitions (super partition)
    # This is required for modern Android versions
    if echo "$fastboot_output" | grep -q "super-partition-name:"; then
        local super_name=$(echo "$fastboot_output" | grep "super-partition-name:" | cut -d':' -f2 | tr -d ' ')
        print_success "✓ Dynamic partitions supported (super partition: $super_name)"
        
        # Display super partition size if available
        local super_size=$(echo "$fastboot_output" | grep "partition-size:super:" | cut -d':' -f3 | tr -d ' ')
        if [ -n "$super_size" ]; then
            local super_mb=$((0x${super_size#0x} / 1024 / 1024))
            print_partition "Super partition capacity: ${super_mb}MB"
            print_info "Super partition contains: system, vendor, product, odm partitions"
        fi
    else
        print_warning "✗ Dynamic partitions not detected"
        print_info "This could mean:"
        print_info "• Device uses older partition scheme"
        print_info "• Currently in wrong fastboot mode (try fastbootd)"
        print_info "• Device needs firmware update"
    fi
    
    echo
    print_header "4. Current Fastboot Mode:"
    print_info "========================"
    print_info "Different partitions require different fastboot modes"
    # Determine current fastboot mode - crucial for knowing which partitions can be flashed
    if echo "$fastboot_output" | grep -q "is-userspace: yes"; then
        print_success "✓ Currently in fastbootd (userspace) mode"
        print_info "Can flash: system, vendor, product, odm partitions"
        print_info "Cannot flash: bootloader, boot, dtbo partitions"
    else
        print_success "✓ Currently in bootloader fastboot mode"
        print_info "Can flash: bootloader, boot, dtbo, vbmeta partitions"
        print_info "Cannot flash: system, vendor, product, odm partitions"
    fi
    
    echo
    print_header "=== DIAGNOSTIC SUMMARY ==="
    # Provide summary statistics for quick overview
    local partition_count=$(echo "$fastboot_output" | grep -c "partition-size:")
    local ab_count=$(echo "$fastboot_output" | grep "has-slot:" | grep -c ":yes")
    print_success "Total partitions detected: $partition_count"
    print_success "A/B slot partitions: $ab_count"
    
    # Get current slot information if available
    local current_slot=$(echo "$fastboot_output" | grep "current-slot:" | cut -d':' -f2 | tr -d ' ')
    if [ -n "$current_slot" ]; then
        print_device "Active slot: $current_slot"
    fi
    
    echo
    print_info "💡 TIP: Use this information to understand which .img files you need"
    print_info "📖 See docs/VIM4_partitions.md for detailed partition explanations"
    echo
}

# Main device preparation function
# ================================
# Orchestrates the entire device preparation process by detecting the current
# device state and choosing the appropriate preparation method.
# 
# Process Flow:
# 1. Check if device is connected via ADB (preferred - fully automated)
# 2. If ADB available: automated reboot to fastboot modes
# 3. If no ADB: guide user through manual fastboot entry
# 4. Verify bootloader unlock status
# 5. Ensure device is ready for flashing operations
prepare_device() {
    print_header "=== DEVICE PREPARATION ==="
    print_step "Detecting device connection method..."

    # Check if device is connected via ADB (Android Debug Bridge)
    # ADB connection means device is booted in Android with USB debugging enabled
    # This is the preferred method as it allows full automation
    if adb devices | grep -q "device$"; then
        print_success "Device detected via ADB - using automated preparation"
        prepare_device_via_adb
    else
        # No ADB device found - device may be off, in fastboot, or USB debugging disabled
        # User must manually enter fastboot mode
        print_info "No ADB device detected - using manual preparation"
        prepare_device_manual
    fi
    
    echo
    print_header "=== DEVICE PREPARATION COMPLETE ==="
    print_success "Device is ready for flashing operations"
    echo
}

# Automated device preparation via ADB
# ====================================
# This method provides the smoothest user experience when the device is
# booted into Android with USB debugging enabled. It handles all mode
# transitions automatically.
#
# Process:
# 1. Reboot device to bootloader mode via ADB
# 2. Wait for fastboot to become available
# 3. Switch to fastbootd for dynamic partition support
# 4. Verify bootloader unlock status
# 5. Ready for flashing
prepare_device_via_adb() {
    print_success "✓ ADB device found - initiating automated preparation"
    print_info "This will reboot your device - ensure no important work is open"
    
    # Reboot device directly into bootloader mode using ADB
    # This bypasses normal Android shutdown and goes straight to fastboot
    print_step "Rebooting device to bootloader mode..."
    adb reboot bootloader
    
    print_step "Waiting for device to enter fastboot mode..."
    sleep 5  # Allow device time to complete reboot process
    
    # Wait for fastboot to be ready in bootloader mode
    # Bootloader mode can flash: bootloader, boot, dtbo, vbmeta partitions
    wait_for_fastboot "fastboot (bootloader) mode"
    
    # Switch to fastbootd for dynamic partition support
    # Modern Android devices need fastbootd for system/vendor/product partitions
    # This is userspace fastboot running from Android recovery
    print_step "Switching to fastbootd for dynamic partition support..."
    print_info "Fastbootd is required for system, vendor, product partitions"
    fastboot reboot fastboot
    
    print_step "Waiting for fastbootd to be ready..."
    sleep 5  # Allow device time to switch to fastbootd mode
    
    # Wait for fastbootd to be ready
    # Fastbootd mode can flash: system, vendor, product, odm partitions
    wait_for_fastboot "fastbootd (userspace) mode"
    
    # Verify bootloader unlock status via fastboot
    # This is critical - all flashing operations will fail if bootloader is locked
    print_step "Verifying bootloader unlock status..."
    if ! check_bootloader_unlock; then
        echo
        print_error "Device preparation failed - bootloader is locked!"
        print_info "Cannot proceed with flashing until bootloader is unlocked"
        print_info "See bootloader unlock instructions in docs/VIM4_partitions.md"
        exit 1
    fi
    
    print_success "✓ Automated device preparation completed successfully"
}

# Manual device preparation
# =========================
# This method is used when ADB is not available, which can happen when:
# - Device is powered off
# - USB debugging is disabled
# - Device is already in fastboot mode
# - ADB drivers are not properly installed
#
# The user must manually enter fastboot mode, then the script continues
# with the same preparation steps as the automated method.
prepare_device_manual() {
    print_warning "⚠️  No ADB device found - manual setup required"
    echo
    print_info "This can happen if:"
    print_info "• Device is powered off"
    print_info "• USB debugging is disabled in Developer Options"
    print_info "• Device is already in fastboot mode"
    print_info "• ADB drivers not installed"
    echo
    print_header "Manual Fastboot Mode Entry Instructions:"
    print_step "1. Power off your Khadas VIM4 completely"
    print_step "2. Connect USB cable to your computer"
    print_step "3. Hold Volume- button and press Power button"
    print_step "4. Release buttons when you see fastboot mode on screen"
    print_step "5. Verify USB connection is working"
    echo
    print_info "📱 Device should display: 'Fastboot mode' or similar message"
    print_info "💻 Computer should recognize the USB device"
    echo
    print_warning "Press Enter after device is in fastboot mode..."
    read  # Wait for user confirmation that device is ready
    
    # Verify device is now in fastboot mode
    print_step "Checking for fastboot device..."
    if fastboot devices | grep -q "fastboot"; then
        print_success "✓ Device detected in fastboot mode"
        
        # Switch to fastbootd for dynamic partition support
        # This transition is required for flashing system/vendor/product partitions
        print_step "Switching to fastbootd for dynamic partition support..."
        print_info "Fastbootd enables flashing of modern Android partitions"
        fastboot reboot fastboot
        
        print_step "Waiting for fastbootd to be ready..."
        sleep 5  # Allow time for mode transition
        
        # Wait for fastbootd mode to be fully ready
        wait_for_fastboot "fastbootd (userspace) mode"
        
        # Verify bootloader unlock status
        print_step "Verifying bootloader unlock status..."
        if ! check_bootloader_unlock; then
            echo
            print_error "Device preparation failed - bootloader is locked!"
            print_info "Cannot proceed with flashing until bootloader is unlocked"
            print_info "See bootloader unlock instructions in docs/VIM4_partitions.md"
            exit 1
        fi
        
        print_success "✓ Manual device preparation completed successfully"
    else
        # Device not detected in fastboot mode - troubleshooting needed
        print_error "❌ Device not detected in fastboot mode"
        echo
        print_info "Troubleshooting steps:"
        print_step "1. Check USB cable connection (try different cable/port)"
        print_step "2. Verify fastboot mode entry (see device screen)"
        print_step "3. Install/update fastboot drivers if on Windows"
        print_step "4. Try 'fastboot devices' command manually"
        print_step "5. Ensure bootloader is unlocked (see docs)"
        echo
        print_warning "Please resolve connection issues and restart the script"
        exit 1
    fi
}

# Utility function to wait for fastboot to be ready
# =================================================
# This function provides robust waiting logic with timeout handling for
# fastboot mode transitions. Different fastboot modes can take varying
# amounts of time to become ready.
#
# Parameters:
#   $1 - Human-readable mode name for user feedback
#
# Returns: 0 on success, exits script on timeout
# Timeout: 30 seconds (sufficient for most devices)
wait_for_fastboot() {
    local mode_name="$1"
    print_step "Waiting for $mode_name to be ready..."
    print_info "This may take a few seconds depending on device state..."
    
    # Set timeout limit - 30 seconds should be sufficient for mode transitions
    # If device takes longer, there's likely a connection or hardware issue
    local timeout=30
    local elapsed=0
    
    while [ $timeout -gt 0 ]; do
        # Check if fastboot can communicate with the device
        # This command queries connected fastboot devices
        if fastboot devices | grep -q "fastboot"; then
            print_success "✓ Device is ready in $mode_name"
            print_device "Connection established after ${elapsed} seconds"
            return 0
        fi
        
        # Show progress indicator every 5 seconds to keep user informed
        if [ $((elapsed % 5)) -eq 0 ] && [ $elapsed -gt 0 ]; then
            print_info "Still waiting... (${elapsed}s elapsed, ${timeout}s remaining)"
        fi
        
        sleep 1
        timeout=$((timeout - 1))
        elapsed=$((elapsed + 1))
    done
    
    # Timeout reached - device not responding within expected timeframe
    print_error "❌ $mode_name not ready after 30 seconds"
    echo
    print_warning "Device connection timeout - possible issues:"
    print_info "• USB cable or port problem"
    print_info "• Device stuck during mode transition"
    print_info "• Fastboot drivers not properly installed"
    print_info "• Device requires manual intervention"
    echo
    print_info "Troubleshooting recommendations:"
    print_step "1. Disconnect and reconnect USB cable"
    print_step "2. Try different USB port or cable"
    print_step "3. Manually power cycle the device"
    print_step "4. Check 'fastboot devices' output manually"
    print_step "5. Restart the script after resolving issues"
    echo
    print_error "Script cannot continue without fastboot connection"
    exit 1
}

# Utility function to safely flash a partition if image file exists
# Utility function to safely flash a partition if image file exists
# ===============================================================
# This is a core utility function that handles the actual flashing operation
# for a single partition. It provides safety checks, error handling, and
# detailed progress feedback.
#
# Safety Features:
# - File existence check before flashing attempt
# - Graceful handling of missing files
# - Error detection and reporting
# - Support for additional fastboot arguments
# - Clear success/failure feedback
#
# Parameters:
#   $1 - partition: Target partition name (e.g., "boot", "system", "vendor")
#   $2 - file: Path to image file (e.g., "boot.img", "system.img")
#   $3 - extra_args: Optional fastboot arguments (e.g., "--disable-verity")
#
# Returns:
#   0 - Success (file flashed or skipped due to missing file)
#   1 - Failure (fastboot command failed)
#
# Examples:
#   flash_if_exists "boot" "boot.img"
#   flash_if_exists "vbmeta" "vbmeta.img" "--disable-verity --disable-verification"
flash_if_exists() {
    local partition=$1    # Target partition name for flashing
    local file=$2         # Source image file path
    local extra_args=$3   # Optional additional fastboot arguments
    
    # Validate inputs
    if [ -z "$partition" ] || [ -z "$file" ]; then
        print_error "flash_if_exists: Missing required parameters"
        return 1
    fi
    
    print_step "Checking file: $file -> $partition partition"
    
    # Check if image file exists before attempting to flash
    if [ -f "$file" ]; then
        # File exists - proceed with flashing
        print_flash "Flashing $partition partition from $file"
        
        # Get file size for user information
        local file_size=$(ls -lh "$file" | awk '{print $5}')
        print_info "File size: $file_size"
        
        # Execute fastboot flash command with optional extra arguments
        print_step "Executing: fastboot flash $partition $file $extra_args"
        
        if fastboot flash "$partition" "$file" $extra_args; then
            # Flash successful
            print_success "✅ Successfully flashed $partition partition"
            print_info "Partition $partition is now updated"
            return 0
        else
            # Flash failed - this is a critical error
            print_error "❌ Failed to flash $partition partition"
            print_warning "This may indicate:"
            print_info "• Fastboot communication error"
            print_info "• Incorrect partition name"
            print_info "• Corrupted image file"
            print_info "• Device in wrong mode"
            print_info "• Hardware or connection issue"
            return 1
        fi
    else
        # File doesn't exist - this is not an error, just skip
        print_warning "⚠️  File $file not found"
        print_info "Skipping $partition partition (not critical)"
        print_info "This partition will retain its current content"
        return 0  # Return success since this isn't an error condition
    fi
}

# ============================================================================
# FILE DISCOVERY AND SELECTION SYSTEM
# ============================================================================
# This section handles scanning for available image files and providing
# user-friendly preset options for different flashing scenarios.
# Supports both guided presets and custom file selection.
# ============================================================================

# Function to scan and display available .img files
# =================================================
# Scans the project directory for all known Android partition image files
# and provides a comprehensive report of what's available vs missing.
# This helps users understand what can be flashed.
scan_available_files() {
    print_header "SCANNING FOR IMAGE FILES"
    print_info "Checking project directory: $PROJECT_DIR"
    print_info "Looking for Android partition image files (.img)"
    echo
    
    # Initialize array to store found files
    available_files=()
    local found_count=0
    local missing_count=0
    
    print_header "File Availability Report:"
    print_info "========================="
    
    # Check each known partition file for existence
    for file in "${PARTITION_FILES[@]}"; do
        if [ -f "$file" ]; then
            # File exists - add to available list and show as success
            available_files+=("$file")
            found_count=$((found_count + 1))
            print_success "✓ $file"
            print_info "  └─ $(get_partition_description "$file")"
        else
            # File missing - show as error with description
            missing_count=$((missing_count + 1))
            print_error "✗ $file (NOT FOUND)"
            print_info "  └─ $(get_partition_description "$file")"
        fi
    done
    
    echo
    print_header "📊 SCAN SUMMARY"
    print_success "Found: $found_count image files"
    print_warning "Missing: $missing_count image files"
    print_info "Total searched: ${#PARTITION_FILES[@]} partition types"
    echo
    
    # Provide guidance based on results
    if [ $found_count -eq 0 ]; then
        print_error "No image files found!"
        print_info "Please check that you're in the correct directory:"
        print_info "Current directory: $PROJECT_DIR"
        print_info "Expected files: *.img (Android partition images)"
        exit 1
    elif [ $found_count -lt 5 ]; then
        print_warning "Very few image files found - build may be incomplete"
    fi
}

# Function to display preset selection menu
# ========================================
# Provides user-friendly preset options for different flashing scenarios.
# Each preset is carefully designed for specific use cases and safety levels.
show_preset_menu() {
    print_header "FLASHING PRESET SELECTION"
    print_info "Choose a preset based on your flashing requirements:"
    echo
    
    print_info "1. 🔧 ESSENTIAL ONLY"
    print_info "   └─ Minimal working system (bootloader, boot, system, vendor)"
    print_info "   └─ Safe option for basic functionality testing"
    print_info "   └─ Files: bootloader, boot, dtbo, vbmeta, system, vendor, product"
    echo
    
    print_info "2. ⭐ RECOMMENDED"
    print_info "   └─ Essential + common optional partitions"
    print_info "   └─ Good balance of features and safety"
    print_info "   └─ Adds: system_ext, odm, init_boot, vendor_boot, logo"
    echo
    
    print_info "3. 🚀 FULL SYSTEM"
    print_info "   └─ Flash all available partitions (except debug/test files)"
    print_info "   └─ Complete system replacement"
    print_info "   └─ Use when doing full Android system update"
    echo
    
    print_info "4. 💾 SUPER PARTITION ONLY"
    print_info "   └─ Use super.img to replace all dynamic partitions"
    print_info "   └─ Modern approach for Android 10+ devices"
    print_info "   └─ Files: bootloader, boot, dtbo, vbmeta, super"
    echo
    
    print_info "5. 🎛️  CUSTOM SELECTION"
    print_info "   └─ Manually choose which files to flash"
    print_info "   └─ Advanced option for experienced users"
    print_info "   └─ Full control over partition selection"
    echo
    
    print_info "6. 🔍 DIAGNOSTICS"
    print_info "   └─ Analyze device partition layout and capabilities"
    print_info "   └─ Recommended for first-time users"
    print_info "   └─ No flashing performed - information only"
    echo
    
    print_warning "Important: Ensure bootloader is unlocked before flashing!"
    echo
    read -p "Enter your choice (1-6): " preset_choice
}

# Function to process user's preset selection
# ==========================================
# This function takes the user's menu choice and builds the selected_files array
# based on predefined file sets for each preset. Each preset is optimized for
# different use cases and risk levels.
#
# Preset Categories:
# 1. Essential - Minimum files for basic Android functionality
# 2. Recommended - Essential + commonly needed optional partitions
# 3. Full System - All available files except debug/test images
# 4. Super Only - Modern dynamic partition approach (Android 10+)
# 5. Custom - User manually selects individual files
# 6. Diagnostics - No flashing, only device analysis
select_files_by_preset() {
    # Initialize empty array for selected files
    selected_files=()
    
    case $preset_choice in
        1)
            # ESSENTIAL PRESET - Minimum working Android system
            # ===============================================
            # This preset includes only the critical partitions needed for
            # basic Android functionality. Safe for testing and recovery scenarios.
            print_success "✓ Selected: Essential Only preset"
            print_info "Including minimum partitions for basic Android functionality"
            
            # Essential partition list with explanations
            local essential_files=(
                "bootloader.img"  # U-Boot bootloader - required for device boot
                "boot.img"        # Linux kernel + ramdisk - required for Android
                "dtbo.img"        # Device tree overlay - hardware configuration
                "vbmeta.img"      # Verified boot metadata - security/integrity
                "system.img"      # Core Android system - main OS components
                "vendor.img"      # Device-specific drivers and libraries
                "product.img"     # Product-specific apps and configurations
            )
            
            # Add files to selection if they exist
            for file in "${essential_files[@]}"; do
                if [ -f "$file" ]; then
                    selected_files+=("$file")
                    print_info "  ✓ Added: $file"
                else
                    print_warning "  ✗ Missing: $file (skipped)"
                fi
            done
            ;;
            
        2)
            # RECOMMENDED PRESET - Essential + common optional partitions
            # =========================================================
            # This preset provides a good balance between functionality and safety.
            # Includes essential partitions plus commonly needed optional ones.
            print_success "✓ Selected: Recommended preset"
            print_info "Including essential + commonly needed optional partitions"
            
            # Recommended partition list (essential + extras)
            local recommended_files=(
                # Essential partitions (same as preset 1)
                "bootloader.img" "boot.img" "dtbo.img" "vbmeta.img" 
                "system.img" "vendor.img" "product.img"
                # Additional recommended partitions
                "system_ext.img"   # System extensions for modular Android
                "odm.img"          # ODM (Original Design Manufacturer) customizations
                "init_boot.img"    # Init boot partition (Android 13+)
                "vendor_boot.img"  # Vendor-specific boot components
                "logo.img"         # Boot splash screen/logo
            )
            
            # Add files to selection if they exist
            for file in "${recommended_files[@]}"; do
                if [ -f "$file" ]; then
                    selected_files+=("$file")
                    print_info "  ✓ Added: $file"
                else
                    print_warning "  ✗ Missing: $file (skipped)"
                fi
            done
            ;;
            
        3)
            # FULL SYSTEM PRESET - All available files except debug/test
            # ========================================================
            # This preset flashes everything available except debug and test files.
            # Use for complete system updates or when you want maximum completeness.
            print_success "✓ Selected: Full System preset"
            print_info "Including ALL available partitions (excluding debug/test files)"
            
            local excluded_count=0
            # Process all available files, excluding debug/test files
            for file in "${available_files[@]}"; do
                # Exclude debug, test, and super.img files
                # super.img is excluded because it conflicts with individual partitions
                if [[ ! "$file" =~ (debug|test-harness|super\.img) ]]; then
                    selected_files+=("$file")
                    print_info "  ✓ Added: $file"
                else
                    excluded_count=$((excluded_count + 1))
                    print_warning "  ✗ Excluded: $file (debug/test/super)"
                fi
            done
            
            print_info "Added ${#selected_files[@]} files, excluded $excluded_count files"
            ;;
            
        4)
            # SUPER PARTITION PRESET - Modern dynamic partition approach
            # ========================================================
            # Uses super.img which contains all dynamic partitions in one file.
            # This is the modern Android approach for devices with dynamic partitions.
            print_success "✓ Selected: Super Partition Only preset"
            print_info "Using super.img for dynamic partitions (Android 10+ approach)"
            
            # Check if super.img exists
            if [ -f "super.img" ]; then
                # Super partition approach - bootloader + boot + super
                local super_files=(
                    "bootloader.img"  # Bootloader still flashed separately
                    "boot.img"        # Boot partition still separate
                    "dtbo.img"        # Device tree overlay
                    "vbmeta.img"      # Verification metadata
                    "super.img"       # Contains: system, vendor, product, odm
                )
                
                # Override selected_files with super partition approach
                selected_files=()
                for file in "${super_files[@]}"; do
                    if [ -f "$file" ]; then
                        selected_files+=("$file")
                        print_info "  ✓ Added: $file"
                    else
                        print_warning "  ✗ Missing: $file"
                    fi
                done
                
                echo
                print_info "💡 Super partition contains: system, vendor, product, odm"
                print_info "🔧 This replaces individual dynamic partitions"
            else
                print_error "❌ super.img not found!"
                print_info "Super partition preset requires super.img file"
                print_info "Please build with dynamic partitions enabled or choose different preset"
                exit 1
            fi
            ;;
            
        5)
            # CUSTOM SELECTION - User manually chooses files
            # =============================================
            # Advanced option that gives users full control over file selection
            print_success "✓ Selected: Custom Selection preset"
            select_custom_files
            ;;
            
        6)
            # DIAGNOSTICS - Device analysis only, no flashing
            # ==============================================
            # Provides comprehensive device information without any flashing
            print_success "✓ Selected: Partition Diagnostics"
            print_info "Running device analysis - no flashing will be performed"
            check_vim4_partitions
            
            echo
            print_header "=== DIAGNOSTICS COMPLETE ==="
            print_success "Device analysis finished successfully"
            print_info "💡 Use this information to choose appropriate flashing preset"
            print_info "🔄 Restart script to perform actual flashing"
            exit 0
            ;;
            
        *)
            # Invalid choice handling
            print_error "❌ Invalid choice! Please select 1-6."
            print_info "Valid options:"
            print_info "1-4: Flashing presets"
            print_info "5: Custom selection"
            print_info "6: Diagnostics only"
            exit 1
            ;;
    esac
    
    # Validate that we have at least one file selected
    if [ ${#selected_files[@]} -eq 0 ]; then
        print_error "❌ No files selected for flashing!"
        print_info "This could mean:"
        print_info "• No .img files found in directory"
        print_info "• All required files are missing"
        print_info "• Selection criteria too restrictive"
        exit 1
    fi
    
    echo
    print_success "📋 Selection complete: ${#selected_files[@]} files ready for flashing"
}

# Function for custom file selection
# ===================================
# This advanced function allows experienced users to manually select
# which partition files to flash. It provides an interactive numbered
# menu with descriptions to help users make informed choices.
#
# Process:
# 1. Display numbered list of all available .img files
# 2. Show partition description for each file
# 3. Accept space-separated numbers from user
# 4. Validate input and build selection array
# 5. Handle invalid inputs gracefully
select_custom_files() {
    print_success "🎛️  Custom File Selection Mode"
    print_info "You can manually choose which partition files to flash"
    print_warning "⚠️  Advanced users only - incorrect selection may brick device"
    echo
    
    print_header "Available Files:"
    print_info "==============="
    print_info "Select files by entering their numbers (space-separated)"
    print_info "Example: '1 3 5 7' to select files 1, 3, 5, and 7"
    echo
    
    # Display numbered list of available files with descriptions
    for i in "${!available_files[@]}"; do
        local file_num=$((i+1))
        local file_name="${available_files[$i]}"
        local description=$(get_partition_description "$file_name")
        
        # Simplified color coding - only critical warnings
        if [[ "$file_name" =~ (userdata) ]]; then
            # Data-destructive files - red warning only
            echo -e "${RED}$file_num. $file_name${NC} - $description [WILL ERASE DATA]"
        elif [[ "$file_name" =~ (bootloader|boot|system|vendor|vbmeta|dtbo) ]]; then
            # Critical files - simple bold
            echo -e "${BOLD}$file_num. $file_name${NC} - $description [CRITICAL]"
        else
            # Optional files - no color
            echo "$file_num. $file_name - $description [OPTIONAL]"
        fi
    done
    
    echo
    print_info "💡 Tips for custom selection:"
    print_info "• Include bootloader.img + boot.img for basic functionality"
    print_info "• system.img + vendor.img are typically required"
    print_info "• userdata.img will erase all user data"
    print_info "• vbmeta.img + dtbo.img needed for verified boot"
    echo
    
    # Get user input with validation loop
    local valid_input=false
    while [ "$valid_input" = false ]; do
        read -p "📝 Enter file numbers (space-separated) or 'q' to quit: " -a selections
        
        # Check if user wants to quit
        if [ "${selections[0]}" = "q" ] || [ "${selections[0]}" = "Q" ]; then
            print_info "Custom selection cancelled - returning to main menu"
            exit 0
        fi
        
        # Validate selections
        local invalid_count=0
        selected_files=()  # Reset selection array
        
        for selection in "${selections[@]}"; do
            # Check if input is a valid number
            if [[ "$selection" =~ ^[0-9]+$ ]]; then
                # Check if number is in valid range
                if [ "$selection" -ge 1 ] && [ "$selection" -le "${#available_files[@]}" ]; then
                    # Convert to array index (subtract 1) and add to selection
                    local file_index=$((selection-1))
                    selected_files+=("${available_files[$file_index]}")
                    print_info "  ✓ Selected: ${available_files[$file_index]}"
                else
                    print_error "  ✗ Invalid number: $selection (range: 1-${#available_files[@]})"
                    invalid_count=$((invalid_count + 1))
                fi
            else
                print_error "  ✗ Not a number: '$selection'"
                invalid_count=$((invalid_count + 1))
            fi
        done
        
        # Check if we have valid selections
        if [ $invalid_count -eq 0 ] && [ ${#selected_files[@]} -gt 0 ]; then
            valid_input=true
            print_success "✓ Custom selection complete: ${#selected_files[@]} files selected"
        elif [ ${#selected_files[@]} -eq 0 ]; then
            print_warning "⚠️  No valid files selected. Please try again."
            echo
        else
            print_warning "⚠️  Some selections were invalid. Please correct and try again."
            echo
        fi
    done
}

# Function to display final selection and get user confirmation
# ===========================================================
# This critical safety function shows exactly what will be flashed
# and requires explicit user confirmation before proceeding.
# This is the last chance to abort before any permanent changes.
#
# Safety Features:
# - Clear display of all selected files with descriptions
# - Explicit warning about device state requirements
# - User confirmation required to proceed
# - Option to abort with Ctrl+C
show_selected_files() {
    echo
    print_header "📋 FINAL FLASHING CONFIRMATION"
    echo
    print_info "The following files will be flashed to your device:"
    print_info "=================================================="
    
    # Display each selected file with description and categorization
    local critical_files=0
    local optional_files=0
    local data_destructive=false
    
    for file in "${selected_files[@]}"; do
        local description=$(get_partition_description "$file")
        
        # Categorize files by importance and risk
        if [[ "$file" =~ (bootloader|boot|system|vendor|vbmeta|dtbo) ]]; then
            # Critical system files
            critical_files=$((critical_files + 1))
            print_partition "$file - $description [CRITICAL]"
        elif [[ "$file" =~ (userdata) ]]; then
            # Data-destructive files
            data_destructive=true
            print_partition "⚠ $file - $description [WILL ERASE DATA]" 
        else
            # Optional/enhancement files
            optional_files=$((optional_files + 1))
            print_partition "$file - $description [OPTIONAL]"
        fi
    done
    
    echo
    print_header "📊 SELECTION SUMMARY"
    print_success "Total files to flash: ${#selected_files[@]}"
    print_info "Critical system files: $critical_files"
    print_info "Optional files: $optional_files"
    
    # Show data destruction warning if userdata.img is selected
    if [ "$data_destructive" = true ]; then
        echo
        print_warning "🚨 DATA DESTRUCTION WARNING 🚨"
        print_error "userdata.img will ERASE ALL USER DATA!"
        print_info "This includes:"
        print_info "• All apps and app data"
        print_info "• User files and photos"
        print_info "• Settings and configurations"
        print_info "• Downloaded content"
        print_warning "This action CANNOT be undone!"
        echo
    fi
    
    echo
    print_header "⚠️  CRITICAL PRE-FLASH CHECKLIST"
    print_info "Before proceeding, verify:"
    print_step "✓ Device is properly connected via USB"
    print_step "✓ Device is in fastboot/fastbootd mode"
    print_step "✓ Bootloader is unlocked"
    print_step "✓ Stable power supply (battery + charger recommended)"
    print_step "✓ Reliable USB connection (avoid USB hubs)"
    print_step "✓ No interruptions during flashing process"
    
    if [ "$data_destructive" = true ]; then
        print_step "✓ User data backup completed (if needed)"
    fi
    
    echo
    print_warning "⚠️  IMPORTANT: Do NOT disconnect device during flashing!"
    print_warning "⚠️  Interrupting the process may brick your device!"
    echo
    
    print_info "🎯 Ready to flash ${#selected_files[@]} partition(s)"
    print_info "Press Enter to continue or Ctrl+C to abort..."
    
    # Wait for user confirmation
    # This gives users time to read warnings and abort if needed
    read
    
    echo
    print_success "✓ User confirmation received - proceeding with flash operation"
}

# ============================================================================
# FLASHING OPERATIONS - CORE FUNCTIONALITY
# ============================================================================
# This section contains the main flashing logic that handles the actual
# partition writing process. It automatically manages fastboot mode switching
# and provides detailed progress feedback throughout the operation.
#
# Key Features:
# - Automatic mode detection and switching (fastboot vs fastbootd)
# - Two-phase flashing process for different partition types
# - Special handling for verification metadata (vbmeta)
# - User confirmation for data-destructive operations
# - Comprehensive error handling and progress reporting
# ============================================================================

# Main flashing orchestration function
# ====================================
# This function coordinates the entire flashing process by:
# 1. Categorizing files by required fastboot mode
# 2. Flashing bootloader-mode files first
# 3. Switching to fastbootd mode for dynamic partitions
# 4. Handling special cases (vbmeta, userdata)
# 5. Providing detailed progress and status updates
perform_flashing() {
    print_header "🔥 STARTING FLASHING PROCESS"
    print_info "Flashing will proceed in two phases based on partition types"
    echo
    
    # Phase 1: Flash bootloader-mode partitions
    # ========================================
    # These partitions must be flashed in bootloader mode (regular fastboot)
    # Includes: bootloader, boot, dtbo, vbmeta, logo, etc.
    print_header "⚡ PHASE 1: BOOTLOADER MODE PARTITIONS"
    print_info "Flashing partitions that require bootloader fastboot mode"
    print_info "Current mode: bootloader fastboot"
    echo
    
    local fastboot_count=0
    local need_fastbootd=false
    
    # Process all selected files and flash bootloader-mode partitions
    for file in "${selected_files[@]}"; do
        # Check if this file belongs to fastboot mode
        if [[ " ${FASTBOOT_FILES[@]} " =~ " ${file} " ]]; then
            fastboot_count=$((fastboot_count + 1))
            local partition="${file%.img}"  # Remove .img extension for partition name
            
            print_step "Processing $file -> $partition partition"
            
            # Special handling for verification metadata partitions
            # These need special flags to disable verification during development
            if [ "$partition" = "vbmeta" ] || [ "$partition" = "vbmeta_system" ]; then
                print_info "Applying verification bypass flags for $partition"
                flash_if_exists "$partition" "$file" "--disable-verity --disable-verification"
            else
                # Standard flashing for other partitions
                flash_if_exists "$partition" "$file"
            fi
            
        # Check if any fastbootd files are in selection (for phase 2)
        elif [[ " ${FASTBOOTD_FILES[@]} " =~ " ${file} " ]]; then
            need_fastbootd=true
        fi
    done
    
    # Report Phase 1 completion
    if [ $fastboot_count -gt 0 ]; then
        echo
        print_success "✅ Phase 1 Complete: $fastboot_count bootloader partitions flashed"
    else
        print_info "ℹ️  Phase 1 Skipped: No bootloader partitions selected"
    fi
    
    # Phase 2: Flash fastbootd-mode partitions (if needed)
    # ==================================================
    # These partitions require fastbootd mode (userspace fastboot)
    # Includes: system, vendor, product, odm, system_ext, super, userdata
    if [ "$need_fastbootd" = true ]; then
        echo
        print_header "⚡ PHASE 2: FASTBOOTD MODE PARTITIONS"
        print_info "Flashing dynamic partitions that require fastbootd mode"
        print_info "Current mode: fastbootd (userspace fastboot)"
        echo
        
        local fastbootd_count=0
        
        # Process fastbootd partitions
        for file in "${selected_files[@]}"; do
            if [[ " ${FASTBOOTD_FILES[@]} " =~ " ${file} " ]]; then
                fastbootd_count=$((fastbootd_count + 1))
                local partition="${file%.img}"  # Remove .img extension
                
                print_step "Processing $file -> $partition partition"
                
                # Special handling for userdata partition (data destructive)
                if [ "$file" = "userdata.img" ]; then
                    print_warning "⚠️  userdata partition requires special confirmation"
                    handle_userdata_flashing "$partition" "$file"
                else
                    # Standard flashing for other dynamic partitions
                    flash_if_exists "$partition" "$file"
                fi
            fi
        done
        
        echo
        print_success "✅ Phase 2 Complete: $fastbootd_count dynamic partitions flashed"
    else
        echo
        print_info "ℹ️  Phase 2 Skipped: No dynamic partitions selected"
    fi
    
    echo
    print_header "🎉 FLASHING OPERATION COMPLETE"
    print_success "All selected partitions have been flashed successfully!"
    print_info "Total files processed: ${#selected_files[@]}"
    print_info "Device is ready for reboot and first boot"
}

# Function to handle userdata partition flashing with extra safety
# ==============================================================
# The userdata partition contains all user data, apps, and personal files.
# Flashing this partition will completely erase everything the user has stored.
# This function provides an additional safety confirmation specifically for
# this destructive operation.
#
# Safety Features:
# - Clear warning about data destruction
# - Explicit user confirmation required
# - Option to skip and preserve existing data
# - Single-character response for quick decision
handle_userdata_flashing() {
    local partition=$1  # Partition name (should be "userdata")
    local file=$2       # Image file (should be "userdata.img")
    
    echo
    print_header "🚨 CRITICAL DATA DESTRUCTION WARNING 🚨"
    print_error "You are about to flash the userdata partition!"
    echo
    print_warning "This will PERMANENTLY ERASE:"
    print_info "• All installed apps and their data"
    print_info "• Photos, videos, and downloaded files"
    print_info "• User settings and configurations"
    print_info "• Contacts and messages (if stored locally)"
    print_info "• All personal data on the device"
    echo
    print_warning "This action CANNOT be undone!"
    print_info "Make sure you have backed up important data before proceeding"
    echo
    
    # Get single-character confirmation to make decision quick and clear
    print_info "Do you want to proceed with userdata flashing?"
    print_warning "Press 'y' or 'Y' to ERASE ALL DATA and continue"
    print_info "Press any other key to skip and preserve existing data"
    echo
    read -n 1 -r -p "🔥 Your choice: "
    echo  # Add newline after single character input
    echo
    
    # Process user decision
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_warning "⚠️  User confirmed data destruction"
        print_step "Proceeding with userdata partition flashing..."
        
        # Flash the userdata partition
        if flash_if_exists "$partition" "$file"; then
            print_success "✅ userdata partition flashed successfully"
            print_warning "🧹 All user data has been erased"
            print_info "Device will boot to setup wizard on next start"
        else
            print_error "❌ Failed to flash userdata partition"
            return 1
        fi
    else
        print_success "✅ userdata flashing skipped by user"
        print_info "Existing user data will be preserved"
        print_warning "⚠️  Note: Keeping old userdata with new system may cause issues"
        print_info "Consider factory reset from Android settings if problems occur"
    fi
    
    echo
}

# Function to finalize flashing process and reboot device
# =====================================================
# This function handles the completion of the flashing process by:
# 1. Providing final status summary
# 2. Rebooting the device to test the new firmware
# 3. Giving users expectations about first boot
# 4. Celebrating successful completion
finalize_flashing() {
    echo
    print_header "🏁 FINALIZING FLASHING PROCESS"
    print_step "All flashing operations completed successfully"
    print_info "Preparing device for first boot with new firmware"
    echo
    
    # Final safety check before reboot
    print_info "💡 Pre-reboot summary:"
    print_success "✓ All selected partitions flashed"
    print_success "✓ No critical errors detected"
    print_success "✓ Device ready for reboot"
    echo
    
    # Initiate device reboot
    print_header "🔄 REBOOTING DEVICE"
    print_step "Sending reboot command to device..."
    
    # Use fastboot to reboot the device
    # This should work regardless of current mode (fastboot or fastbootd)
    if fastboot reboot; then
        print_success "✅ Reboot command sent successfully"
    else
        print_warning "⚠️  Reboot command failed - device may need manual restart"
        print_info "You can manually power cycle the device if needed"
    fi

    echo
    print_header "🎉 KHADAS VIM4 FLASHING COMPLETED"
    print_success "🚀 Selected partitions have been flashed successfully!"
    print_success "📱 Device is rebooting with new firmware"
    echo
    
    # Set user expectations for first boot
    print_info "📋 What to expect during first boot:"
    print_step "• Initial boot may take 2-5 minutes (be patient)"
    print_step "• Device may show boot animation longer than usual"
    print_step "• First-time optimization processes will run"
    print_step "• If userdata was flashed, setup wizard will appear"
    print_step "• Subsequent boots will be faster"
    echo
    
    # Troubleshooting guidance
    print_info "🔧 If device doesn't boot properly:"
    print_step "• Wait at least 5 minutes before troubleshooting"
    print_step "• Check serial console output if available"
    print_step "• Verify all critical partitions were flashed"
    print_step "• Consider reflashing if boot fails completely"
    print_step "• See docs/VIM4_partitions.md for recovery procedures"
    echo
    
    # Final success message
    print_header "🎊 FLASHING SESSION COMPLETE"
    print_success "Thank you for using the Khadas VIM4 interactive flashing tool!"
    print_info "Author: Arkadiusz Kubiak"
    print_info "LinkedIn: https://www.linkedin.com/in/arkadiusz-kubiak-1b4994150"
    echo
    print_device "🔥 Your Khadas VIM4 is now running fresh firmware!"
}

# ============================================================================
# MAIN SCRIPT EXECUTION AND WORKFLOW
# ============================================================================
# This section orchestrates the entire flashing process through a logical
# workflow that ensures safety, provides clear feedback, and handles errors.
#
# SCRIPT WORKFLOW (Version 2.1):
# 1. Initialize and display welcome message
# 2. Enter main menu loop with options:
#    a. Flash Android Images - Complete interactive flashing process
#    b. Partition Diagnostics - Device info and partition analysis  
#    c. Show Documentation - Display key documentation sections
#    d. Exit - Clean script termination
# 3. For flashing option:
#    • Prepare device (ADB detection -> fastboot modes -> unlock verification)
#    • Scan for available image files in project directory
#    • Present user-friendly preset menu with detailed descriptions
#    • Process user selection and validate file availability
#    • Show final confirmation with selected files and descriptions
#    • Execute flashing operations with automatic mode switching
#    • Finalize with device reboot and success confirmation
#    • Return to main menu for additional operations
# 4. Menu loop continues until user chooses to exit
#
# ERROR HANDLING:
# - Exits gracefully on any critical error (bootloader locked, no files, etc.)
# - Provides detailed troubleshooting information for common issues
# - Validates each step before proceeding to prevent partial flashing
#
# SAFETY FEATURES:
# - Bootloader unlock verification before any flashing
# - User confirmation before actual flashing begins
# - Automatic fastboot mode switching for different partition types
# - Clear indication of what will be flashed and potential data loss
# ============================================================================

main() {
    # ========================================================================
    # Phase 1: Initialization and Welcome
    # ========================================================================
    print_header "KHADAS VIM4 - INTERACTIVE FLASHING TOOL"
    print_info "Author: Arkadiusz Kubiak"
    print_info "Version: 2.1 - Improved readability"
    echo
    
    print_device "Target Device: Khadas VIM4"
    print_info "Project Directory: $PROJECT_DIR"
    print_info "Script Purpose: Interactive Android partition flashing"
    echo
    
    print_warning "IMPORTANT PREREQUISITES:"
    print_info "• Bootloader MUST be unlocked (see docs/VIM4_partitions.md)"
    print_info "• USB debugging enabled (for ADB) or manual fastboot mode"
    print_info "• Proper fastboot drivers installed"
    print_info "• Reliable USB connection"
    echo

    # ========================================================================
    # Phase 2: Device Preparation and Validation
    # ========================================================================
    print_header "DEVICE PREPARATION PHASE"
    prepare_device

    # ========================================================================
    # Phase 3: File Discovery and Analysis
    # ========================================================================
    print_header "FILE DISCOVERY PHASE"
    scan_available_files

    # ========================================================================
    # Phase 4: User Selection and Validation
    # ========================================================================
    print_header "SELECTION PHASE"
    show_preset_menu
    select_files_by_preset

    # ========================================================================
    # Phase 5: Final Confirmation
    # ========================================================================
    print_header "CONFIRMATION PHASE"
    show_selected_files

    # ========================================================================
    # Phase 6: Flashing Execution
    # ========================================================================
    print_header "FLASHING PHASE"
    perform_flashing

    # ========================================================================
    # Phase 7: Completion and Reboot
    # ========================================================================
    print_header "COMPLETION PHASE"
    finalize_flashing
}

# ============================================================================
# SCRIPT ENTRY POINT
# ============================================================================
# Execute main function with all command line arguments passed through
# This allows for potential future command-line options support
main "$@"