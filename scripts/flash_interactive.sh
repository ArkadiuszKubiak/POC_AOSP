#!/bin/bash

# Khadas VIM4 - Interactive Flash Selection
# Allows user to select which .img files to flash
#
# Author: Arkadiusz Kubiak
# LinkedIn: https://www.linkedin.com/in/arkadiusz-kubiak-1b4994150
# Purpose: Interactive Android .img flashing tool for Khadas VIM4

set -e  # Exit on any error

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

# Configure project directory - change this path as needed
# Leave empty to use script's location automatically
PROJECT_PATH="/home/arek/workspace/android_khadas/out/target/product/kvim4"

# Set project directory
if [ -n "$PROJECT_PATH" ]; then
    PROJECT_DIR="$PROJECT_PATH"
else
    PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Change to project directory
cd "$PROJECT_DIR"

echo "=== Khadas VIM4 - Interactive Flash Selection ==="
echo "Project directory: $PROJECT_DIR"
echo "This script allows you to select which .img files to flash"
echo

# Automatic device preparation
echo "=== Preparing device for flashing ==="

# Check if bootloader is unlocked
echo "⚠ BOOTLOADER UNLOCK CHECK ⚠"
echo "Checking bootloader unlock status..."

# Function to check bootloader variables via fastboot
check_bootloader_unlock() {
    echo "Checking U-Boot environment variables..."
    
    # Try to get unlocked variable - available in both bootloader and fastbootd mode
    local unlocked_status=$(fastboot getvar unlocked 2>&1 | grep "unlocked:" | cut -d':' -f2 | tr -d ' ')
    
    echo "Current bootloader status:"
    echo "• unlocked = $unlocked_status"
    
    # Check if bootloader is unlocked
    if [ "$unlocked_status" = "yes" ]; then
        echo "✓ Bootloader is properly unlocked (unlocked=yes)"
        return 0
    else
        echo "✗ Bootloader is still locked!"
        echo
        echo "Expected value:"
        echo "• unlocked = yes (currently: $unlocked_status)"
        echo
        echo "To unlock bootloader:"
        echo "1. Connect USB-TTL converter to VIM4 GPIO"
        echo "2. Enter U-Boot console (serial 921600 baud)"
        echo "3. Run commands:"
        echo "   kvim4# setenv lock 0"
        echo "   kvim4# setenv avb2 0"
        echo "   kvim4# saveenv"
        echo "   kvim4# reset"
        echo
        echo "See detailed instructions: docs/VIM4_partitions.md"
        echo "Section: 'Khadas VIM4 Bootloader Unlock'"
        return 1
    fi
}

# Manual confirmation if automatic check fails
echo "Before proceeding, ensure your Khadas VIM4 bootloader is unlocked!"
echo "If you haven't unlocked it yet, see: docs/VIM4_partitions.md"
echo "Section: 'Khadas VIM4 Bootloader Unlock'"
echo
echo "Press 'y' if bootloader is unlocked, or any other key to exit..."
read -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please unlock bootloader first using the documentation."
    echo "Location: docs/VIM4_partitions.md - 'Khadas VIM4 Bootloader Unlock' section"
    exit 1
fi

echo "Checking ADB connection..."

# Check if device is connected via ADB
if adb devices | grep -q "device$"; then
    echo "✓ ADB device found - rebooting to bootloader..."
    adb reboot bootloader
    
    echo "Waiting for device to enter fastboot mode..."
    sleep 5
    
    # Wait for fastboot to be ready
    echo "Waiting for fastboot to be ready..."
    timeout=30
    while [ $timeout -gt 0 ]; do
        if fastboot devices | grep -q "fastboot"; then
            echo "✓ Device is in fastboot mode"
            break
        fi
        sleep 1
        timeout=$((timeout - 1))
    done
    
    if [ $timeout -eq 0 ]; then
        echo "⚠ Device not detected in fastboot mode after 30 seconds"
        echo "Please manually put device in fastboot mode and press Enter..."
        read
    fi
    
    # Reboot to fastboot (fastbootd) for dynamic partitions support
    echo "Switching to fastbootd for dynamic partition support..."
    fastboot reboot fastboot
    
    echo "Waiting for fastbootd to be ready..."
    sleep 5
    
    # Wait for fastbootd to be ready
    timeout=30
    while [ $timeout -gt 0 ]; do
        if fastboot devices | grep -q "fastboot"; then
            echo "✓ Device is in fastbootd mode"
            break
        fi
        sleep 1
        timeout=$((timeout - 1))
    done
    
    if [ $timeout -eq 0 ]; then
        echo "ERROR: Fastbootd not ready after 30 seconds"
        echo "Please manually put device in fastboot mode and restart script"
        exit 1
    fi
    
    # Check bootloader unlock status via fastboot (after switching to fastbootd)
    if ! check_bootloader_unlock; then
        echo
        echo "ERROR: Bootloader is not properly unlocked!"
        echo "Please unlock bootloader before flashing."
        exit 1
    fi
    
else
    echo "⚠ No ADB device found"
    echo "Please connect device via USB and ensure USB debugging is enabled"
    echo "Or manually put device in fastboot mode"
    echo "Press Enter when device is ready..."
    read
    
    # Check if device is now in fastboot mode and verify unlock status
    if fastboot devices | grep -q "fastboot"; then
        echo "✓ Device detected in fastboot mode"
        
        # Switch to fastbootd for dynamic partitions
        echo "Switching to fastbootd for dynamic partition support..."
        fastboot reboot fastboot
        
        echo "Waiting for fastbootd to be ready..."
        sleep 5
        
        # Wait for fastbootd to be ready
        timeout=30
        while [ $timeout -gt 0 ]; do
            if fastboot devices | grep -q "fastboot"; then
                echo "✓ Device is in fastbootd mode"
                break
            fi
            sleep 1
            timeout=$((timeout - 1))
        done
        
        if [ $timeout -eq 0 ]; then
            echo "ERROR: Fastbootd not ready after 30 seconds"
            echo "Please manually put device in fastboot mode and restart script"
            exit 1
        fi
        
        # Check bootloader unlock status (after switching to fastbootd)
        if ! check_bootloader_unlock; then
            echo
            echo "ERROR: Bootloader is not properly unlocked!"
            echo "Please unlock bootloader before flashing."
            exit 1
        fi
    else
        echo "ERROR: Device not detected in fastboot mode"
        echo "Please put device in fastboot mode and restart script"
        exit 1
    fi
fi

echo
echo "=== Device is ready for flashing ==="
echo

# Define all available partitions and their descriptions
declare -A partitions=(
    ["bootloader.img"]="Bootloader (U-Boot) - Required for boot"
    ["dtb.img"]="Device Tree Blob - Required for hardware detection"
    ["boot.img"]="Kernel + Ramdisk - Required for Android boot"
    ["vbmeta.img"]="Verification metadata - Required for verified boot"
    ["system.img"]="Main Android system - Required"
    ["vendor.img"]="Device-specific files - Required"
    ["product.img"]="Product apps - Recommended"
    ["system_ext.img"]="System extensions - Recommended"
    ["odm.img"]="ODM modifications - Recommended"
    ["userdata.img"]="User data partition - Optional (erases data)"
    ["dtbo.img"]="Device Tree Overlay - Optional"
    ["logo.img"]="Boot logo - Optional"
    ["init_boot.img"]="Init boot (Android 13+) - Optional"
    ["vendor_boot.img"]="Vendor boot partition - Optional"
    ["vbmeta_system.img"]="System verification metadata - Optional"
    ["odm_ext.img"]="ODM extensions - Optional"
    ["oem.img"]="OEM partition - Optional"
    ["vendor_dlkm.img"]="Vendor kernel modules - Optional"
    ["system_dlkm.img"]="System kernel modules - Optional"
    ["odm_dlkm.img"]="ODM kernel modules - Optional"
    ["super.img"]="Super partition (all dynamic partitions) - Alternative"
)

# Check which files exist
echo "Available .img files:"
echo "====================="
available_files=()
for file in "${!partitions[@]}"; do
    if [ -f "$file" ]; then
        available_files+=("$file")
        echo "✓ $file - ${partitions[$file]}"
    else
        echo "✗ $file - ${partitions[$file]} (NOT FOUND)"
    fi
done

echo
echo "====================="
echo

# Preset selections
echo "Select flashing preset:"
echo "1. Essential only (bootloader, dtb, boot, vbmeta, system, vendor, product)"
echo "2. Recommended (essential + system_ext, odm, dtbo, logo)"
echo "3. Full system (all available files except debug)"
echo "4. Super partition only (super.img replaces dynamic partitions)"
echo "5. Custom selection"
echo
read -p "Enter your choice (1-5): " preset_choice

selected_files=()

case $preset_choice in
    1)
        echo "Selected: Essential only"
        for file in "bootloader.img" "dtb.img" "boot.img" "vbmeta.img" "system.img" "vendor.img" "product.img"; do
            if [ -f "$file" ]; then
                selected_files+=("$file")
            fi
        done
        ;;
    2)
        echo "Selected: Recommended"
        for file in "bootloader.img" "dtb.img" "boot.img" "vbmeta.img" "system.img" "vendor.img" "product.img" "system_ext.img" "odm.img" "dtbo.img" "logo.img"; do
            if [ -f "$file" ]; then
                selected_files+=("$file")
            fi
        done
        ;;
    3)
        echo "Selected: Full system"
        for file in "${available_files[@]}"; do
            if [[ ! "$file" =~ (debug|test-harness|super\.img) ]]; then
                selected_files+=("$file")
            fi
        done
        ;;
    4)
        echo "Selected: Super partition only"
        if [ -f "super.img" ]; then
            selected_files=("bootloader.img" "dtb.img" "boot.img" "vbmeta.img" "super.img")
        else
            echo "ERROR: super.img not found!"
            exit 1
        fi
        ;;
    5)
        echo "Custom selection:"
        echo "Enter the numbers of files to flash (space-separated):"
        for i in "${!available_files[@]}"; do
            echo "$((i+1)). ${available_files[$i]} - ${partitions[${available_files[$i]}]}"
        done
        read -p "Enter numbers: " -a selections
        
        for selection in "${selections[@]}"; do
            if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#available_files[@]}" ]; then
                selected_files+=("${available_files[$((selection-1))]}")
            fi
        done
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

# Show selected files
echo
echo "Files selected for flashing:"
echo "============================"
for file in "${selected_files[@]}"; do
    echo "• $file - ${partitions[$file]}"
done

echo
echo "Make sure device is in fastboot mode!"
echo "Press Enter to continue or Ctrl+C to abort..."
read

# Function to flash if file exists
flash_if_exists() {
    local partition=$1
    local file=$2
    local extra_args=$3
    
    if [ -f "$file" ]; then
        echo "Flashing $partition..."
        fastboot flash "$partition" "$file" $extra_args
    else
        echo "WARNING: $file not found, skipping $partition"
    fi
}

# Determine which files need fastboot mode vs fastbootd mode
fastboot_files=("bootloader.img" "dtb.img" "boot.img" "vbmeta.img" "dtbo.img" "logo.img" "init_boot.img" "vendor_boot.img" "vbmeta_system.img")
fastbootd_files=("system.img" "vendor.img" "product.img" "system_ext.img" "odm.img" "odm_ext.img" "oem.img" "vendor_dlkm.img" "system_dlkm.img" "odm_dlkm.img" "super.img" "userdata.img")

# Flash fastboot mode files
echo "=== Step 1: Flashing bootloader and boot partitions (fastboot mode) ==="

# Check if we need to flash any fastboot mode files
fastboot_needed=false
for file in "${selected_files[@]}"; do
    if [[ " ${fastboot_files[@]} " =~ " ${file} " ]]; then
        fastboot_needed=true
        break
    fi
done

# If fastboot files are needed, switch back to bootloader fastboot mode
if [ "$fastboot_needed" = true ]; then
    echo "Switching back to bootloader fastboot mode for bootloader/boot partitions..."
    fastboot reboot-bootloader
    
    echo "Waiting for bootloader fastboot to be ready..."
    sleep 5
    
    # Wait for bootloader fastboot to be ready
    timeout=30
    while [ $timeout -gt 0 ]; do
        if fastboot devices | grep -q "fastboot"; then
            echo "✓ Device is in bootloader fastboot mode"
            break
        fi
        sleep 1
        timeout=$((timeout - 1))
    done
    
    if [ $timeout -eq 0 ]; then
        echo "ERROR: Bootloader fastboot not ready after 30 seconds"
        echo "Please manually put device in bootloader fastboot mode and restart script"
        exit 1
    fi
fi

need_fastbootd=false
for file in "${selected_files[@]}"; do
    if [[ " ${fastboot_files[@]} " =~ " ${file} " ]]; then
        partition="${file%.img}"
        if [ "$partition" = "vbmeta" ] || [ "$partition" = "vbmeta_system" ]; then
            flash_if_exists "$partition" "$file" "--disable-verity --disable-verification"
        else
            flash_if_exists "$partition" "$file"
        fi
    elif [[ " ${fastbootd_files[@]} " =~ " ${file} " ]]; then
        need_fastbootd=true
    fi
done

# Flash fastbootd mode files (switch to fastbootd if needed)
if [ "$need_fastbootd" = true ]; then
    echo "=== Step 2: Flashing dynamic partitions (fastbootd mode) ==="
    
    # Switch to fastbootd mode for dynamic partitions
    echo "Switching to fastbootd for dynamic partition support..."
    fastboot reboot fastboot
    
    echo "Waiting for fastbootd to be ready..."
    sleep 5
    
    # Wait for fastbootd to be ready
    timeout=30
    while [ $timeout -gt 0 ]; do
        if fastboot devices | grep -q "fastboot"; then
            echo "✓ Device is in fastbootd mode"
            break
        fi
        sleep 1
        timeout=$((timeout - 1))
    done
    
    if [ $timeout -eq 0 ]; then
        echo "ERROR: Fastbootd not ready after 30 seconds"
        echo "Please manually put device in fastbootd mode and restart script"
        exit 1
    fi
    
    # Flash dynamic partitions
    for file in "${selected_files[@]}"; do
        if [[ " ${fastbootd_files[@]} " =~ " ${file} " ]]; then
            partition="${file%.img}"
            if [ "$file" = "userdata.img" ]; then
                echo "WARNING: Flashing userdata.img will erase all user data!"
                echo "Press 'y' to continue or any other key to skip..."
                read -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    flash_if_exists "$partition" "$file"
                else
                    echo "Skipping userdata.img"
                fi
            else
                flash_if_exists "$partition" "$file"
            fi
        fi
    done
fi

# Reboot
echo "=== Final Step: Rebooting device ==="
echo "Flashing complete! Rebooting device..."
fastboot reboot

echo
echo "=== FLASHING COMPLETED ==="
echo "Selected partitions have been flashed successfully!"
echo4
echo "Device is rebooting..."
echo "First boot may take several minutes."
echo
echo "=== TROUBLESHOOTING ==="
echo "If flashing failed with 'FAILED (remote: Partition is locked)' errors:"
echo "• Your bootloader is still locked"
echo "• Follow unlock instructions in: docs/VIM4_partitions.md"
echo "• Section: 'Khadas VIM4 Bootloader Unlock'"
echo
echo "If device doesn't boot after flashing:"
echo "• Try flashing essential partitions only"
echo "• Check if all required files were flashed successfully"
echo "• Verify bootloader unlock status"
